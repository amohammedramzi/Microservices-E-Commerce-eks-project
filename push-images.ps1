# Configuration
$REGION = "us-east-1"
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$ECR_URL = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Services to build and push
$SERVICES = @(
    "emailservice",
    "checkoutservice",
    "recommendationservice",
    "frontend",
    "paymentservice",
    "productcatalogservice",
    "cartservice",
    "loadgenerator",
    "currencyservice",
    "shippingservice",
    "adservice"
)

Write-Host "Starting ECR Push Process for Account: ${ACCOUNT_ID} in Region: ${REGION}" -ForegroundColor Cyan

# Authenticate Docker to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ECR Login Failed. Please check your AWS credentials." -ForegroundColor Red
    exit
}

# Loop through services
foreach ($SERVICE in $SERVICES) {
    Write-Host "----------------------------------------------------" -ForegroundColor Yellow
    Write-Host "🚀 Processing Service: ${SERVICE}" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------" -ForegroundColor Yellow

    $SERVICE_DIR = "./src/${SERVICE}"
    
    if (-not (Test-Path $SERVICE_DIR)) {
        Write-Host "⚠️  Directory ${SERVICE_DIR} not found. Skipping..." -ForegroundColor Magenta
        continue
    }

    # Build the image
    Write-Host "Building ${SERVICE}..."
    docker build -t "${SERVICE}:latest" $SERVICE_DIR

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed for ${SERVICE}. Skipping push." -ForegroundColor Red
        continue
    }

    # Tag the image for ECR
    Write-Host "Tagging ${SERVICE}..."
    docker tag "${SERVICE}:latest" "${ECR_URL}/${SERVICE}:latest"

    # Push to ECR
    Write-Host "Pushing ${SERVICE} to ECR..."
    docker push "${ECR_URL}/${SERVICE}:latest"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ${SERVICE} pushed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Push failed for ${SERVICE}." -ForegroundColor Red
    }
}

Write-Host "----------------------------------------------------" -ForegroundColor Cyan
Write-Host "🎉 ECR Push Process Completed!" -ForegroundColor Cyan
