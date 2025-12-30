#!/bin/bash

# Configuration
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Services to build and push
SERVICES=(
    "emailservice"
    "checkoutservice"
    "recommendationservice"
    "frontend"
    "paymentservice"
    "productcatalogservice"
    "cartservice"
    "loadgenerator"
    "currencyservice"
    "shippingservice"
    "adservice"
)

echo "Starting ECR Push Process for Account: ${ACCOUNT_ID} in Region: ${REGION}"

# Authenticate Docker to ECR
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL}

if [ $? -ne 0 ]; then
    echo "❌ ECR Login Failed. Please check your AWS credentials."
    exit 1
fi

# Loop through services
for SERVICE in "${SERVICES[@]}"; do
    echo "----------------------------------------------------"
    echo "🚀 Processing Service: ${SERVICE}"
    echo "----------------------------------------------------"

    SERVICE_DIR="./src/${SERVICE}"
    
    if [ ! -d "$SERVICE_DIR" ]; then
        echo "⚠️  Directory ${SERVICE_DIR} not found. Skipping..."
        continue
    fi

    # Build the image
    echo "Building ${SERVICE}..."
    
    DOCKERFILE="${SERVICE_DIR}/Dockerfile"
    CONTEXT="${SERVICE_DIR}"
    
    if [ ! -f "$DOCKERFILE" ]; then
        if [ -f "${SERVICE_DIR}/src/Dockerfile" ]; then
            DOCKERFILE="${SERVICE_DIR}/src/Dockerfile"
            CONTEXT="${SERVICE_DIR}/src"
            echo "ℹ️  Using nested Dockerfile and context for ${SERVICE} at ${CONTEXT}"
        else
            echo "❌ Dockerfile not found for ${SERVICE}. Skipping push."
            continue
        fi
    fi

    docker build -t ${SERVICE}:latest -f ${DOCKERFILE} ${CONTEXT}

    if [ $? -ne 0 ]; then
        echo "❌ Build failed for ${SERVICE}. Skipping push."
        continue
    fi

    # Tag the image for ECR
    echo "Tagging ${SERVICE}..."
    docker tag ${SERVICE}:latest ${ECR_URL}/${SERVICE}:latest

    # Push to ECR
    echo "Pushing ${SERVICE} to ECR..."
    docker push ${ECR_URL}/${SERVICE}:latest

    if [ $? -eq 0 ]; then
        echo "✅ ${SERVICE} pushed successfully!"
    else
        echo "❌ Push failed for ${SERVICE}."
    fi
done

echo "----------------------------------------------------"
echo "🎉 ECR Push Process Completed!"
