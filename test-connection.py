"""
NATS Connection Test Script
Tests connectivity to the Azure NATS server from on-premises or Azure clients
"""

import asyncio
import sys
from datetime import datetime
from nats.aio.client import Client as NATS

# Configuration
NATS_SERVER = "nats://nats-storeone.norwayeast.azurecontainer.io:4222"  # Update after deployment
NATS_USER = "admin"
NATS_PASSWORD = "Admin@2025"

async def test_connection():
    """Test basic NATS connection"""
    print("=" * 60)
    print("NATS Server Connection Test")
    print("=" * 60)
    print(f"Server: {NATS_SERVER}")
    print(f"User: {NATS_USER}")
    print("-" * 60)
    
    nc = NATS()
    
    try:
        # Connect to NATS server
        print("\n1. Connecting to NATS server...")
        await nc.connect(
            servers=[NATS_SERVER],
            user=NATS_USER,
            password=NATS_PASSWORD,
            connect_timeout=10
        )
        print("✓ Connected successfully!")
        print(f"   Client ID: {nc.client_id}")
        print(f"   Connected to: {nc.connected_url}")
        
        # Test publish
        print("\n2. Testing publish...")
        test_subject = "test.connection"
        test_message = f"Test message at {datetime.now().isoformat()}"
        await nc.publish(test_subject, test_message.encode())
        print(f"✓ Published to '{test_subject}'")
        print(f"   Message: {test_message}")
        
        # Test subscribe
        print("\n3. Testing subscribe...")
        messages_received = []
        
        async def message_handler(msg):
            message = msg.data.decode()
            messages_received.append(message)
            print(f"✓ Received message on '{msg.subject}': {message}")
        
        # Subscribe to test subject
        await nc.subscribe("test.>", cb=message_handler)
        print(f"✓ Subscribed to 'test.>'")
        
        # Publish a few test messages
        print("\n4. Publishing test messages...")
        for i in range(3):
            subject = f"test.message.{i}"
            message = f"Message #{i+1} at {datetime.now().isoformat()}"
            await nc.publish(subject, message.encode())
            await asyncio.sleep(0.1)  # Small delay
        
        # Wait for messages
        await asyncio.sleep(1)
        print(f"\n✓ Received {len(messages_received)} messages")
        
        # Test request-reply
        print("\n5. Testing request-reply pattern...")
        
        # Set up responder
        async def request_handler(msg):
            response = f"Reply to: {msg.data.decode()}"
            await nc.publish(msg.reply, response.encode())
        
        await nc.subscribe("requests.echo", cb=request_handler)
        await asyncio.sleep(0.1)
        
        # Send request
        request_data = "Hello, NATS!"
        try:
            response = await nc.request("requests.echo", request_data.encode(), timeout=2)
            print(f"✓ Request-Reply successful")
            print(f"   Request: {request_data}")
            print(f"   Response: {response.data.decode()}")
        except asyncio.TimeoutError:
            print("✗ Request timed out")
        
        # Server info
        print("\n6. Server Information:")
        print(f"   Max Payload: {nc.max_payload} bytes")
        
        print("\n" + "=" * 60)
        print("All tests completed successfully! ✓")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n✗ Error: {str(e)}")
        print(f"   Type: {type(e).__name__}")
        sys.exit(1)
    
    finally:
        # Close connection
        if nc.is_connected:
            await nc.close()
            print("\nConnection closed.")

async def test_device_simulation():
    """Simulate on-premises device communication"""
    print("\n" + "=" * 60)
    print("On-Premises Device Simulation")
    print("=" * 60)
    
    nc = NATS()
    
    try:
        # Connect as on-prem device
        await nc.connect(
            servers=[NATS_SERVER],
            user="onprem_device",
            password="OnPremDevice@2025"
        )
        print("✓ Connected as on-prem device")
        
        # Subscribe to commands
        async def command_handler(msg):
            print(f"[COMMAND] Received: {msg.data.decode()} on {msg.subject}")
        
        await nc.subscribe("commands.>", cb=command_handler)
        print("✓ Subscribed to commands")
        
        # Publish device data
        device_id = "device001"
        for i in range(3):
            # Temperature reading
            temp_data = f'{{"device": "{device_id}", "temperature": {20 + i}, "timestamp": "{datetime.now().isoformat()}"}}'
            await nc.publish(f"devices.{device_id}.temperature", temp_data.encode())
            print(f"[TELEMETRY] Sent: {temp_data}")
            await asyncio.sleep(0.5)
        
        # Test receiving command (simulate from another client)
        await nc.publish(f"commands.{device_id}", b'{"action": "reboot"}')
        await asyncio.sleep(0.5)
        
        print("\n✓ Device simulation completed")
        
    except Exception as e:
        print(f"✗ Device simulation error: {str(e)}")
    
    finally:
        if nc.is_connected:
            await nc.close()

def main():
    """Main entry point"""
    print("\nNATS Server Test Utility")
    print("Make sure to update NATS_SERVER with your Azure deployment URL\n")
    
    # Check if nats-py is installed
    try:
        import nats
    except ImportError:
        print("Error: nats-py is not installed")
        print("Install it with: pip install nats-py")
        sys.exit(1)
    
    # Run tests
    loop = asyncio.get_event_loop()
    
    try:
        # Basic connection test
        loop.run_until_complete(test_connection())
        
        # Device simulation
        loop.run_until_complete(test_device_simulation())
        
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
