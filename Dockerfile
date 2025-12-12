FROM nats:latest

# Copy custom configuration
COPY nats-server.conf /etc/nats/nats-server.conf

# Create data directory for JetStream
RUN mkdir -p /data/jetstream && \
    chown -R nats:nats /data

# Expose ports
# 4222: Client connections
# 8222: HTTP monitoring
# 6222: Cluster routing (for future use)
EXPOSE 4222 8222 6222

# Run NATS server with custom config
CMD ["nats-server", "-c", "/etc/nats/nats-server.conf"]
