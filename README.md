# NATS Server - Azure Deployment

A simple NATS server deployment for Azure Container Instance to communicate with on-premises devices.

## 📁 Project Structure

- `nats-server.conf` - NATS server configuration with basic authentication
- `Dockerfile` - Custom Docker image with configuration
- `docker-compose.yml` - Local testing with Docker Compose
- `azure-deploy.json` - Azure Resource Manager (ARM) template
- `azure-deploy.parameters.json` - ARM template parameters
- `deploy-to-azure.ps1` - PowerShell deployment script
- `test-connection.py` - Python script to test NATS connectivity

## 🚀 Quick Deploy to Azure

### Prerequisites

1. **Azure CLI** installed and configured
   ```powershell
   az --version
   az login
   ```

2. **NATS CLI** (optional, for testing)
   ```powershell
   # Windows (using Chocolatey)
   choco install nats-cli
   
   # Or download from: https://github.com/nats-io/natscli/releases
   ```

### Deploy to StoreOne Resource Group

Simply run the deployment script:

```powershell
.\deploy-to-azure.ps1
```

This will:
- Deploy NATS server to your StoreOne resource group
- Create a public IP with DNS name
- Configure ports 4222 (client) and 8222 (monitoring)
- Enable JetStream for message persistence

### Manual Deployment

If you prefer manual deployment:

```powershell
az deployment group create \
  --resource-group StoreOne \
  --template-file azure-deploy.json \
  --parameters azure-deploy.parameters.json
```

## 🔐 Security Configuration

### Default Credentials

The deployment uses **basic authentication**:

| User | Password | Permissions |
|------|----------|-------------|
| `admin` | `Admin@2025` | Full access (publish/subscribe to all subjects) |
| `azure_client` | `AzureClient@2025` | Full access (for Azure services) |
| `onprem_device` | `OnPremDevice@2025` | Publish: `devices.>`, Subscribe: `commands.>`, `config.>` |

⚠️ **Important**: Change these passwords in production!

### Connection URLs

After deployment, you'll receive:
- **NATS URL**: `nats://<your-fqdn>:4222`
- **Monitoring**: `http://<your-fqdn>:8222`

## 🧪 Testing the Deployment

### 1. Using NATS CLI

```powershell
# Save connection context
nats context save azure --server=nats://<your-fqdn>:4222 --user=admin --password=Admin@2025

# Select context
nats context select azure

# Test connection
nats server ping

# View server info
nats server info

# Monitor in real-time
nats server check
```

### 2. Using Python Client

```powershell
# Install NATS Python client
pip install nats-py

# Run test script
python test-connection.py
```

### 3. Check Monitoring Dashboard

Open your browser to: `http://<your-fqdn>:8222`

Endpoints:
- `/varz` - Server variables
- `/connz` - Connection info
- `/routez` - Route info
- `/subsz` - Subscription info
- `/healthz` - Health check

## 💡 Connecting from On-Premises Devices

### Python Example

```python
import asyncio
from nats.aio.client import Client as NATS

async def main():
    nc = NATS()
    
    # Connect to Azure NATS server
    await nc.connect(
        servers=["nats://<your-fqdn>:4222"],
        user="onprem_device",
        password="OnPremDevice@2025"
    )
    
    # Publish device data
    await nc.publish("devices.sensor1.temperature", b'{"value": 22.5}')
    
    # Subscribe to commands
    async def message_handler(msg):
        print(f"Received: {msg.data.decode()}")
    
    await nc.subscribe("commands.>", cb=message_handler)
    
    # Keep connection alive
    while True:
        await asyncio.sleep(1)

if __name__ == '__main__':
    asyncio.run(main())
```

### .NET Example

```csharp
using NATS.Client;

var cf = new ConnectionFactory();
var opts = ConnectionFactory.GetDefaultOptions();
opts.Url = "nats://<your-fqdn>:4222";
opts.User = "onprem_device";
opts.Password = "OnPremDevice@2025";

using (var c = cf.CreateConnection(opts))
{
    // Publish device data
    c.Publish("devices.sensor1.temperature", 
        Encoding.UTF8.GetBytes("{\"value\": 22.5}"));
    
    // Subscribe to commands
    var s = c.SubscribeAsync("commands.>");
    s.MessageHandler += (sender, args) =>
    {
        Console.WriteLine($"Received: {args.Message.Data}");
    };
    s.Start();
    
    Console.ReadLine();
}
```

## 📊 Subject Naming Convention

Recommended patterns:

```
devices.<location>.<device-id>.<metric>    # Device telemetry
commands.<location>.<device-id>            # Commands to devices
config.<location>.<device-id>              # Configuration updates
events.<location>.<event-type>             # General events
```

## 🔧 Configuration Changes

To modify NATS configuration:

1. Edit `nats-server.conf`
2. Redeploy using the script

For advanced features (clustering, TLS), update the ARM template.

## 📈 Monitoring & Troubleshooting

### View Container Logs

```powershell
az container logs --resource-group StoreOne --name nats-server-storeone
```

### Check Container Status

```powershell
az container show --resource-group StoreOne --name nats-server-storeone --query "instanceView.state"
```

### Restart Container

```powershell
az container restart --resource-group StoreOne --name nats-server-storeone
```

## 💰 Cost Estimation

Azure Container Instance pricing (approximate):
- **CPU**: 1 vCPU × ~$0.0000125/second = ~$32/month
- **Memory**: 1.5 GB × ~$0.0000014/second = ~$3.5/month
- **Total**: ~$35-40/month

## 🔒 Production Recommendations

1. **Enable TLS/SSL** for encrypted connections
2. **Use Azure Key Vault** for credentials
3. **Implement NKeys or JWT** authentication
4. **Set up Azure Monitor** for alerting
5. **Configure backup** for JetStream data
6. **Use Azure Virtual Network** for private connectivity
7. **Implement rate limiting** in NATS config
8. **Regular security audits** and password rotation

## 📚 Additional Resources

- [NATS Documentation](https://docs.nats.io)
- [Azure Container Instances](https://docs.microsoft.com/azure/container-instances/)
- [NATS Security](https://docs.nats.io/running-a-nats-service/configuration/securing_nats)

## 🆘 Support

For issues or questions:
1. Check NATS logs: `az container logs --resource-group StoreOne --name nats-server-storeone`
2. Verify network connectivity from on-prem to Azure
3. Check firewall rules on both sides
4. Validate credentials and permissions

## 📝 License

This deployment configuration is provided as-is for your use.
