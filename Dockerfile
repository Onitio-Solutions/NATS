FROM nats:latest

# Copy custom configuration
COPY nats-server.conf /nats-server.conf

# Expose ports
# 4222: Client connections
# 8222: HTTP monitoring
# 6222: Cluster routing (for future use)
EXPOSE 4222 8222 6222

# Run NATS server with inline config for basic auth
CMD ["nats-server", "-p", "4222", "-m", "8222", "--user", "admin", "--pass", "Admin@2025", "-js"]
