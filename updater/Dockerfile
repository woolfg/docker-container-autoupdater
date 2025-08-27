FROM alpine:latest

# Install docker CLI and bash, vim, docker compose plugin
RUN apk add --no-cache docker bash vim docker-compose

# Copy update script and entrypoint
COPY update.sh /app/update.sh
COPY entrypoint.sh /app/entrypoint.sh

# Make scripts executable
RUN chmod +x /app/update.sh /app/entrypoint.sh

# Create shared directory with write permissions for all users
# This allows the trigger container (running as non-root) to write trigger files
RUN mkdir -p /shared && chmod 777 /shared

# Run as root for Docker socket access - this is acceptable since the container
# is isolated and only performs Docker operations
WORKDIR /app

# Use the entrypoint script to manage update monitoring
CMD ["/app/entrypoint.sh"]
