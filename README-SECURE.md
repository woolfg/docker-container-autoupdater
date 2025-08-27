# Docker Swarm Autoupdater - Secure Architecture

This project provides a secure Docker Swarm autoupdater with separated responsibilities for enhanced security.

## Architecture

The system is split into two separate containers:

### 1. Updater Container (`/updater`)
- **Purpose**: Handles the actual Docker updates
- **Security**: Isolated container with Docker socket access only
- **Base**: Alpine Linux (minimal attack surface)
- **User**: Root (required for Docker socket access)
- **Access**: Docker socket only, no network exposure

**Security Note**: The updater runs as root by design since:
- It needs Docker socket access for container management
- It's completely isolated from external networks
- It has no public-facing endpoints
- Container isolation provides sufficient security boundaries

### 2. Trigger Container (`/trigger`) - Optional
- **Purpose**: Provides HTTP webhook endpoint for triggering updates
- **Security**: No Docker socket access, runs as non-root
- **Base**: Node.js Alpine
- **User**: Non-root user (node:1000) 
- **Access**: Shared volume only for trigger file

## Security Benefits

1. **Container Isolation**: Separate containers with different privilege levels
2. **Principle of Least Privilege**: Only the isolated updater has elevated permissions
3. **Minimal Attack Surface**: Public service has no Docker access
4. **File-based Communication**: Simple, secure inter-container messaging
5. **Network Isolation**: Updater has no network exposure, trigger has no system access

## Security Architecture

The security model follows these principles:

- **Updater Container**: Runs as root but is completely isolated
  - No network ports exposed
  - Only Docker socket access
  - Minimal Alpine base image
  - Container isolation provides security boundary

- **Trigger Container**: Runs as non-root with minimal privileges
  - Network-facing but no system access
  - Only file system access to shared volume
  - Cannot execute system commands

## Additional Security Considerations

For production deployments, consider these additional security measures:

### Network Security
```yaml
# Network isolation example
services:
  updater:
    build: ./updater
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - internal  # No external network access
    
  trigger:
    build: ./trigger
    networks:
      - external  # Internet-facing
      - internal  # Communicate with updater
```

### Monitoring and Logging
- Monitor Docker socket access
- Log all update operations
- Set up alerts for failed updates
- Consider using Docker Bench Security for container hardening

## Usage

### Full Setup (with webhook trigger)
```bash
docker-compose up -d
```

This starts both:
- Updater service (monitoring for updates)
- Trigger service (HTTP webhook on port 8080)

### Updater Only (scheduled updates only)
```bash
docker-compose -f docker-compose.updater-only.yaml up -d
```

This starts only the updater service without the public-facing webhook.

## Communication

- Both containers share a volume (`trigger-volume`)
- Trigger service writes timestamp to `/shared/update-trigger`
- Updater service monitors this file and removes it after processing
- If no trigger file, updater runs on schedule (every 15 minutes by default)

## Configuration

### Environment Variables

#### Updater Service
- `CHECK_INTERVAL`: How often to check for trigger file (default: 5 seconds)
- `UPDATE_INTERVAL`: Scheduled update interval (default: 900 seconds = 15 minutes)
- `TRIGGER_FILE`: Location of trigger file (default: `/shared/update-trigger`)

#### Trigger Service
- `PORT`: HTTP server port (default: 3000)
- `HOOK`: Webhook endpoint path (default: `/hook123456789`)
- `TRIGGER_FILE`: Location of trigger file (default: `/shared/update-trigger`)

## API Endpoints

### Trigger Service
- `GET /health` - Health check endpoint
- `GET /{HOOK}` - Webhook to trigger update
- `GET /*` - 404 for all other paths

### Example Webhook Call
```bash
curl http://localhost:8080/update-Nohn0lahGh5ahnaeng9Xolaewu2fae
```

## Migration from Single Container

If you're migrating from the old single-container setup:
1. The webhook endpoint remains the same
2. Port mapping stays at 8080
3. All existing labels and service configurations work unchanged
4. You can run either configuration based on your security requirements

## Development

Each container can be built independently:

```bash
# Build updater
docker build -t autoupdater-updater ./updater

# Build trigger  
docker build -t autoupdater-trigger ./trigger
```
