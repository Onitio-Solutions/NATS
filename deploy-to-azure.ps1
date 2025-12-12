# Deploy NATS Server to Azure Container Instance
# Resource Group: StoreOne
# Subscription: 8c020b54-b237-4d6e-82ba-190f6a415d1d

param(
    [string]$ResourceGroup = "StoreOne",
    [string]$SubscriptionId = "8c020b54-b237-4d6e-82ba-190f6a415d1d",
    [string]$Location = "norwayeast"
)

# Set Azure context
Write-Host "Setting Azure subscription context..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId

# Verify resource group exists
Write-Host "Verifying resource group '$ResourceGroup'..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "Resource group does not exist. Creating..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location
}

# Deploy NATS server to Azure Container Instance
Write-Host "`nDeploying NATS server to Azure Container Instance..." -ForegroundColor Cyan
az deployment group create `
    --resource-group $ResourceGroup `
    --template-file azure-deploy.json `
    --parameters azure-deploy.parameters.json

# Get deployment outputs
Write-Host "`nRetrieving deployment information..." -ForegroundColor Cyan
$deployment = az deployment group show `
    --resource-group $ResourceGroup `
    --name azure-deploy `
    --query "properties.outputs" -o json | ConvertFrom-Json

# Display connection information
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "NATS Server Deployed Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Connection Details:" -ForegroundColor Yellow
Write-Host "  NATS URL:       $($deployment.natsClientUrl.value)" -ForegroundColor White
Write-Host "  Monitoring URL: $($deployment.monitoringUrl.value)" -ForegroundColor White
Write-Host "  Public IP:      $($deployment.containerIPv4Address.value)" -ForegroundColor White
Write-Host "  FQDN:           $($deployment.containerFQDN.value)" -ForegroundColor White
Write-Host ""
Write-Host "Credentials (Basic Auth):" -ForegroundColor Yellow
Write-Host "  Admin User:     admin" -ForegroundColor White
Write-Host "  Admin Password: Admin@2025" -ForegroundColor White
Write-Host ""
Write-Host "Test the server with:" -ForegroundColor Yellow
Write-Host "  nats context save azure --server=$($deployment.natsClientUrl.value) --user=admin --password=Admin@2025" -ForegroundColor Cyan
Write-Host "  nats context select azure" -ForegroundColor Cyan
Write-Host "  nats server ping" -ForegroundColor Cyan
Write-Host ""
Write-Host "Or visit the monitoring page:" -ForegroundColor Yellow
Write-Host "  $($deployment.monitoringUrl.value)" -ForegroundColor Cyan
Write-Host ""
