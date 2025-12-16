FROM nats:latest

# Expose ports
# 4222: Client connections
# 8222: HTTP monitoring
# 6222: Cluster routing (for future use)
EXPOSE 4222 8222 6222

# Run NATS server with basic auth and JetStream enabled
CMD ["nats-server", "-p", "4222", "-m", "8222", "--user", "admin", "--pass", "Admin@2025", "-js"]
