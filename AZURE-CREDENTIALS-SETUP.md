# Setup Azure Credentials for GitHub Actions

## Create Azure Service Principal

Run this command to create a service principal with Contributor access to your StoreOne resource group:

```powershell
az ad sp create-for-rbac `
  --name "github-nats-deployer" `
  --role contributor `
  --scopes /subscriptions/8c020b54-b237-4d6e-82ba-190f6a415d1d/resourceGroups/StoreOne `
  --sdk-auth
```

This will output JSON credentials like:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "8c020b54-b237-4d6e-82ba-190f6a415d1d",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## Add Secret to GitHub

1. Go to: https://github.com/Onitio-Solutions/NATS/settings/secrets/actions
2. Click **"New repository secret"**
3. Name: `AZURE_CREDENTIALS`
4. Value: Paste the entire JSON output from above
5. Click **"Add secret"**

## Test the Deployment

Once the secret is added:

1. Go to: https://github.com/Onitio-Solutions/NATS/actions
2. Click on **"Build and Deploy NATS to Azure"** workflow
3. Click **"Run workflow"** → **"Run workflow"**

The workflow will:
- ✅ Build the Docker image
- ✅ Push to GitHub Container Registry (private)
- ✅ Deploy to Azure Container Instances
- ✅ Display connection information

## Manual Deployment

If you need to deploy manually without GitHub Actions:

```powershell
.\deploy-from-github.ps1
```

But with the automated workflow, every push to `main` will automatically deploy!
