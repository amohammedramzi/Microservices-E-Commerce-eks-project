$files = Get-ChildItem -Path "kubernetes-files/*.yaml"
$oldAccount = "242201296943"
$newAccount = "339712986249"

foreach ($file in $files) {
    Write-Host "Processing $($file.Name)..."
    $content = Get-Content $file.FullName -Raw
    
    # Replace Account ID
    $content = $content -replace $oldAccount, $newAccount
    
    # Replace tags with :latest for ECR images
    # Regex looks for the ECR URL followed by service name and any digit tag
    $content = $content -replace 'dkr\.ecr\.us-east-1\.amazonaws\.com/([^:]+):(\d+)', 'dkr.ecr.us-east-1.amazonaws.com/$1:latest'
    
    Set-Content -Path $file.FullName -Value $content -NoNewline
}
Write-Host "Done!"
