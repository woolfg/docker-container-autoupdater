# Docker Swarm Autoupdater

Ssolution for automatically updating Docker Swarm services and Docker Compose containers when new images are available.

## Service Configuration

To enable auto-updates for your services, just add this label:

```yaml
services:
  your-app:
    image: your-app:latest
    labels:
      - "docker_autoupdater.enable=true"
    # ... rest of your service configuration
```

## 🏗️ Architecture

This project uses a **two-container architecture** that separates responsibilities for enhanced security:

```
┌─────────────────────────────────────────────────────────────┐
│                    External Network                         │
│                                                             │
│  ┌─────────────┐    HTTP Webhook    ┌─────────────────────┐ │
│  │   GitHub    │ ─────────────────► │   Trigger Service   │ │
│  │  Registry   │    /webhook        │  (Port 8080)        │ │
│  │   CI/CD     │                    │  • Node.js App      │ │
│  └─────────────┘                    │  • Non-root user    │ │
│                                     │  • No Docker access │ │
│                                     └─────────────────────┘ │
└─────────────────────────────────────────────┬───────────────┘
                                              │
                                    ┌─────────▼──────────┐
                                    │   Shared Volume    │
                                    │  /shared/trigger   │
                                    └─────────┬──────────┘
                                              │
┌─────────────────────────────────────────────┼───────────────┐
│                 Internal Network            │               │
│                                    ┌────────▼───────────┐   │
│                                    │  Updater Service   │   │
│                                    │  • Root user       │   │
│                                    │  • Docker socket   │   │
│                                    │  • No network      │   │
│                                    │  • Monitors file   │   │
│                                    └─────────┬──────────┘   │
│                                              │              │
│  ┌─────────────────────────────────────────┐ │              │
│  │         Docker Socket                   │ │              │
│  │  ┌─────────────┐  ┌─────────────┐       │ │              │
│  │  │   Service   │  │   Service   │       │ ┘ Updates      │
│  │  │   app-web   │  │   app-api   │ ...   │   Containers   │
│  │  └─────────────┘  └─────────────┘       │                │
│  └─────────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────┘

```

## 🔒 Why Two Containers?

**Security through separation of concerns:**

1. **Trigger Container** (`woolfg/docker-swarm-autoupdater-trigger`)
   - Handles HTTP webhooks from external sources
   - Is connted to the outside world
   - Runs as non-root user
   - **No Docker socket access** - can't control containers
   - Only writes trigger files to shared volume

2. **Updater Container** (`woolfg/docker-swarm-autoupdater-updater`)
   - Monitors for trigger files
   - Runs scheduled updates every 15 minutes
   - **No network access** - can't be reached from outside
   - Has Docker socket access for container management

This architecture ensures that even if the public-facing trigger service is compromised, attackers cannot directly access Docker or your containers.

## 🚀 Quick Start

### Docker Swarm

```yaml
services:
  # Updater service - runs as root with Docker socket access (isolated)
  updater:
    image: woolfg/docker-swarm-autoupdater-updater:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - trigger-volume:/shared
    environment:
      CHECK_INTERVAL: 5      # Check for triggers every 5 seconds
      UPDATE_INTERVAL: 900   # Auto-update every 15 minutes
      TRIGGER_FILE: /shared/update-trigger
    restart: unless-stopped
    network_mode: "none"     # No network access for security
    deploy:
      placement:
        constraints:
          - node.role == manager  # Must run on manager node

  # Trigger service - public facing, no privileged access
  trigger:
    image: woolfg/docker-swarm-autoupdater-trigger:latest
    ports:
      - "8080:3000"
    volumes:
      - trigger-volume:/shared
    environment:
      PORT: 3000
      HOOK: /update-YOUR_SECRET_WEBHOOK_PATH_HERE
      TRIGGER_FILE: /shared/update-trigger
    restart: unless-stopped
    deploy:
      placement:
        constraints:
          - node.role == manager  # Must run on the same node as updater to be able to share the volume

volumes:
  trigger-volume:
```

### Docker Compose

```yaml
version: '3.8'

services:
  updater:
    image: woolfg/docker-swarm-autoupdater-updater:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - trigger-volume:/shared
    environment:
      TRIGGER_FILE: /shared/update-trigger
    restart: unless-stopped

  trigger:
    image: woolfg/docker-swarm-autoupdater-trigger:latest
    ports:
      - "8080:3000"
    volumes:
      - trigger-volume:/shared
    environment:
      HOOK: /update-YOUR_SECRET_WEBHOOK_PATH_HERE
      TRIGGER_FILE: /shared/update-trigger
    restart: unless-stopped

volumes:
  trigger-volume:
```

### Updater Only

If you only want scheduled updates without webhooks:

```yaml
services:
  updater:
    image: woolfg/docker-swarm-autoupdater-updater:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      UPDATE_INTERVAL: 300  # Check every 5 minutes
    restart: unless-stopped
```

## Webhook Usage

Once deployed, trigger updates by calling your webhook:

```bash
# Trigger an update
curl -X GET http://your-server:8080/update-YOUR_SECRET_WEBHOOK_PATH_HERE

# Response
{
  "message": "Update trigger created",
  "timestamp": "2025-08-27T10:24:42.266Z",
  "triggerFile": "/shared/update-trigger"
}
```

## Configuration

### Environment Variables

#### Updater Service
| Variable | Default | Description |
|----------|---------|-------------|
| `CHECK_INTERVAL` | `5` | How often to check for trigger file (seconds) |
| `UPDATE_INTERVAL` | `900` | Scheduled update interval (seconds) |
| `TRIGGER_FILE` | `/shared/update-trigger` | Path to trigger file |

#### Trigger Service
| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | HTTP server port |
| `HOOK` | `/hook123456789` | Webhook endpoint path |
| `TRIGGER_FILE` | `/shared/update-trigger` | Path to trigger file |


## 🤝 Contributions

Thanks to [@mre](https://github.com/mre) for the input and code reviews.

## 📄 License

MIT License - see LICENSE file for details.
