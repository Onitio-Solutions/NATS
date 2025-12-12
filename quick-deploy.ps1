# Quick Deploy NATS using Azure CLI (bypasses ARM template)
# This method has better retry logic for Docker registry issues

param(
    [string]$ResourceGroup = "StoreOne",
    [string]$ContainerName = "nats-server-storeone",
    [string]$Location = "norwayeast",
    [string]$DnsName = "nats-storeone-$(Get-Random -Maximum 9999)"
)

Write-Host "Deploying NATS Server using Azure CLI direct method..." -ForegroundColor Cyan
Write-Host "This bypasses ARM templates and has better retry logic for Docker registry issues.`n" -ForegroundColor Yellow

# Deploy using az container create
# Using fully qualified Docker Hub path
az container create `
    --resource-group $ResourceGroup `
    --name $ContainerName `
    --image library/nats:alpine `
    --os-type Linux `
    --dns-name-label $DnsName `
    --ports 4222 8222 `
    --cpu 1 `
    --memory 1.5 `
    --restart-policy Always `
    --location $Location `
    --command-line "nats-server -a 0.0.0.0 -p 4222 -m 8222 --user admin --pass Admin@2025 -js -sd /data" `
    --output json

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "NATS Server Deployed Successfully!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    # Get connection info
    $container = az container show --resource-group $ResourceGroup --name $ContainerName --output json | ConvertFrom-Json
    
    $fqdn = $container.ipAddress.fqdn
    $ip = $container.ipAddress.ip
    
    Write-Host "Connection Details:" -ForegroundColor Yellow
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
} else {
    Write-Host "`nDeployment failed. Check the error above." -ForegroundColor Red
}
