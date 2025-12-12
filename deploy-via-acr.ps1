# Deploy NATS using Azure Container Registry (ACR)
# This avoids Docker Hub connectivity issues entirely

param(
    [string]$ResourceGroup = "StoreOne",
    [string]$Location = "northeurope",
    [string]$AcrName = "storenatsacr$(Get-Random -Maximum 9999)",
    [string]$ContainerName = "nats-server-storeone"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "NATS Deployment via Azure Container Registry" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "This method avoids Docker Hub connectivity issues`n" -ForegroundColor Yellow

# Step 1: Create Azure Container Registry
Write-Host "[1/4] Creating Azure Container Registry..." -ForegroundColor Cyan
$acrResult = az acr create `
    --resource-group $ResourceGroup `
    --name $AcrName `
    --sku Basic `
    --location $Location `
    --admin-enabled true `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create ACR" -ForegroundColor Red
    exit 1
}

$acrLoginServer = $acrResult.loginServer
Write-Host "✓ ACR created: $acrLoginServer" -ForegroundColor Green

# Step 2: Import NATS image from Docker Hub to ACR (Azure handles the pull)
Write-Host "`n[2/4] Importing NATS image to ACR (this may take 2-3 minutes)..." -ForegroundColor Cyan
az acr import `
    --name $AcrName `
    --source docker.io/library/nats:latest `
    --image nats:latest `
    --resource-group $ResourceGroup

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Import failed. Trying alternative method..." -ForegroundColor Yellow
    
    # Alternative: use ACR tasks to build from a simple Dockerfile
    Write-Host "Building NATS image in ACR using ACR Tasks..." -ForegroundColor Cyan
    
    # Create a temporary build context
    $tempDir = New-Item -ItemType Directory -Path "$env:TEMP\nats-build-$(Get-Random)" -Force
    
$dockerfileContent = @"
FROM nats:latest
CMD ["nats-server", "-a", "0.0.0.0", "-p", "4222", "-m", "8222", "--user", "admin", "--pass", "Admin@2025", "-js"]
"@
    $dockerfileContent | Out-File -FilePath "$tempDir\Dockerfile" -Encoding UTF8
    
    az acr build --registry $AcrName --image nats:latest --file "$tempDir\Dockerfile" $tempDir
    Remove-Item -Recurse -Force $tempDir
}

Write-Host "✓ NATS image available in ACR" -ForegroundColor Green

# Step 3: Get ACR credentials
Write-Host "`n[3/4] Retrieving ACR credentials..." -ForegroundColor Cyan
$acrCreds = az acr credential show --name $AcrName --output json | ConvertFrom-Json
$acrUsername = $acrCreds.username
$acrPassword = $acrCreds.passwords[0].value

Write-Host "✓ Credentials retrieved" -ForegroundColor Green

# Step 4: Deploy container from ACR
Write-Host "`n[4/4] Deploying NATS container from ACR..." -ForegroundColor Cyan
$dnsLabel = "nats-storeone-$(Get-Random -Maximum 9999)"

az container create `
    --resource-group $ResourceGroup `
    --name $ContainerName `
    --image "${acrLoginServer}/nats:latest" `
    --registry-login-server $acrLoginServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --os-type Linux `
    --dns-name-label $dnsLabel `
    --ports 4222 8222 `
    --cpu 1 `
    --memory 1.5 `
    --restart-policy Always `
    --location $Location `
    --command-line "nats-server -a 0.0.0.0 -p 4222 -m 8222 --user admin --pass Admin@2025 -js -sd /data" `
    --output json

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host "NATS Server Deployed Successfully!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    
    # Get connection info
    $container = az container show --resource-group $ResourceGroup --name $ContainerName --output json | ConvertFrom-Json
    
    $fqdn = $container.ipAddress.fqdn
    $ip = $container.ipAddress.ip
    
    Write-Host "`nConnection Details:" -ForegroundColor Yellow
    Write-Host "  NATS URL:       nats://${fqdn}:4222" -ForegroundColor White
    Write-Host "  Monitoring URL: http://${fqdn}:8222" -ForegroundColor White
    Write-Host "  Public IP:      $ip" -ForegroundColor White
    Write-Host "  FQDN:           $fqdn" -ForegroundColor White
    Write-Host ""
    Write-Host "Credentials:" -ForegroundColor Yellow
    Write-Host "  Username: admin" -ForegroundColor White
    Write-Host "  Password: Admin@2025" -ForegroundColor White
    Write-Host ""
    Write-Host "Test with:" -ForegroundColor Yellow
    Write-Host "  curl http://${fqdn}:8222/varz" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Azure Container Registry: $acrLoginServer" -ForegroundColor Yellow
} else {
    Write-Host "`n✗ Deployment failed." -ForegroundColor Red
}
