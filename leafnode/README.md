# NATS Leaf Node Setup

A leaf node connects your on-premises network to the Azure NATS server.

## Quick Start

### Prerequisites
- Docker Desktop installed and running
- Network access to Azure (port 4222)

### Deploy Leaf Node

1. **Navigate to the leafnode folder:**
   ```powershell
   cd "c:\Git\Nats Server\leafnode"
   ```

2. **Start the leaf node:**
   ```powershell
   docker-compose up -d
   ```

3. **Verify it's running:**
   ```powershell
   docker-compose ps
   docker-compose logs
   ```

4. **Check connection to Azure:**
   ```powershell
   curl http://localhost:8222/leafz
   ```

## How It Works

```
On-Prem Devices → Leaf Node (localhost:4222) → Azure NATS (nats-storeone-6537:4222)
```

**Benefits:**
- Local devices connect to `localhost:4222` (fast, no internet required for local pub/sub)
- Leaf node automatically forwards to/from Azure
- If connection to Azure drops, leaf node buffers messages
- Transparent failover and reconnection

## Connecting Local Devices

### Python Example
```python
import asyncio
from nats.aio.client import Client as NATS

async def main():
    nc = NATS()
    
    # Connect to local leaf node
    await nc.connect(
        servers=["nats://localhost:4222"],
        user="local",
        password="local123"
    )
    
    # Publish to Azure through leaf node
    await nc.publish("devices.sensor1.temp", b'{"value": 22.5}')
    
    # Subscribe to commands from Azure
    async def message_handler(msg):
        print(f"Received: {msg.data.decode()}")
    
    await nc.subscribe("commands.>", cb=message_handler)
    
    await asyncio.sleep(60)
    await nc.close()

if __name__ == '__main__':
    asyncio.run(main())
```

### .NET Example
```csharp
using NATS.Client;

var opts = ConnectionFactory.GetDefaultOptions();
opts.Url = "nats://localhost:4222";
opts.User = "local";
opts.Password = "local123";

using (var c = new ConnectionFactory().CreateConnection(opts))
{
    // Publish
    c.Publish("devices.sensor1.temp", Encoding.UTF8.GetBytes("{\"value\": 22.5}"));
    
    // Subscribe
    var s = c.SubscribeAsync("commands.>");
    s.MessageHandler += (sender, args) =>
    {
        Console.WriteLine($"Received: {Encoding.UTF8.GetString(args.Message.Data)}");
    };
    s.Start();
    
    Console.ReadLine();
}
```

## Management Commands

**Stop leaf node:**
```powershell
docker-compose down
```

**Restart leaf node:**
```powershell
docker-compose restart
```

**View logs:**
```powershell
docker-compose logs -f
```

**Check status:**
```powershell
docker-compose ps
curl http://localhost:8222/varz
curl http://localhost:8222/leafz  # Shows leaf node connections
```

## Configuration Changes

To modify settings, edit `nats-leafnode.conf` and restart:

```powershell
docker-compose restart
```

## Troubleshooting

**Leaf node not connecting to Azure:**
- Check firewall allows outbound port 4222
- Verify Azure NATS server is running
- Check logs: `docker-compose logs`

**Clients can't connect to leaf node:**
- Ensure Docker Desktop is running
- Check port 4222 is not used by another app: `netstat -ano | findstr :4222`
- Verify credentials in your client code

**Monitor connection:**
```powershell
# Check leaf node status
curl http://localhost:8222/leafz

# Check Azure server from leaf node
docker-compose exec nats-leafnode nats-server -sl nats://admin:Admin@2025@nats-storeone-6537.northeurope.azurecontainer.io:4222
```

## Production Considerations

1. **Use TLS** for encrypted connection to Azure
2. **Change default passwords** in nats-leafnode.conf
3. **Set up auto-start** with Docker Desktop settings
4. **Monitor** the leaf node health endpoint
5. **Firewall rules** - allow local network to port 4222
