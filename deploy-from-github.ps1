# Deploy NATS Server from GitHub Container Registry
# Run this after pushing code to GitHub and the Actions workflow completes

param(
    [Parameter(Mandatory=$true)]
    [string]$GithubUsername,  # Your GitHub username or org
    
    [string]$ResourceGroup = "StoreOne",
    [string]$Location = "northeurope",
    [string]$ContainerName = "nats-server-storeone",
    [string]$ImageTag = "latest"
)

$ImageName = "ghcr.io/${GithubUsername}/nats-server/nats-server:${ImageTag}"
$dnsLabel = "nats-storeone-$(Get-Random -Maximum 9999)"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "NATS Deployment from GitHub Container Registry" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Image: $ImageName`n" -ForegroundColor Yellow

Write-Host "Deploying NATS container..." -ForegroundColor Cyan

az container create `
    --resource-group $ResourceGroup `
    --name $ContainerName `
    --image $ImageName `
    --os-type Linux `
    --dns-name-label $dnsLabel `
    --ports 4222 8222 `
    --cpu 1 `
    --memory 1.5 `
    --restart-policy Always `
    --location $Location `
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
    Write-Host "Test the deployment:" -ForegroundColor Yellow
    Write-Host "  curl http://${fqdn}:8222/varz" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "`nDeployment failed. Check the error above." -ForegroundColor Red
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "  1. Your GitHub Actions workflow has completed successfully" -ForegroundColor White
    Write-Host "  2. The container image is public in GitHub Packages" -ForegroundColor White
    Write-Host "  3. You used the correct GitHub username" -ForegroundColor White
}
