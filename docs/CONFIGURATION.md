# Configuration Guide

Detailed configuration instructions for all home server services.

## Environment Variables

All configuration is done through the `.env` file. Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

## Service-Specific Configuration

### Timezone

Set your timezone for all services:
```env
TZ=America/New_York
```

Common timezones: `America/New_York`, `Europe/London`, `Australia/Sydney`, `UTC`

Full list: [Wikipedia - List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

### Network Configuration

```env
DOMAIN=homeserver.local           # Your local domain
EXTERNAL_IP=192.168.1.100         # Your server's IP address
COMPOSE_PROJECT_NAME=homeserver   # Docker Compose project name
```

### File Browser

```env
FILE_BROWSER_PORT=8080
FILE_BROWSER_ROOT=/mnt/media
```

**Configuration**:
1. Access http://localhost:8080
2. Default credentials: admin/admin
3. Change password in Settings > Profile
4. Create users in Settings > Users
5. Configure permissions per user

### Vaultwarden

```env
VAULTWARDEN_PORT=8000
VAULTWARDEN_ADMIN_TOKEN=<your-secure-token>
VAULTWARDEN_DOMAIN=http://your-domain:8000
VAULTWARDEN_LOG_LEVEL=info
```

**First Time Setup**:
1. Access http://localhost:8000
2. Click "Create account"
3. Set email and password
4. Verify email (if configured)
5. Download Bitwarden extensions for browsers

**Admin Panel**:
1. Access http://localhost:8000/admin
2. Enter `VAULTWARDEN_ADMIN_TOKEN` from .env
3. Configure:
   - Invitation organization
   - SMTP for notifications
   - Backup settings

### Hoarder

```env
HOARDER_PORT=3000
HOARDER_DB_PASSWORD=secure-password
```

**Setup**:
1. First user created becomes admin
2. Access http://localhost:3000
3. Create account with email/password
4. Configure profile settings
5. Install browser extension from GitHub

**AI Features**:
- Requires API keys (optional)
- Can function without AI enabled
- Local image processing available

### Portainer

```env
PORTAINER_PORT=9000
PORTAINER_EDGE_PORT=8001
```

**Initial Setup**:
1. Access http://localhost:9000
2. Create admin user
3. Connect to local Docker socket
4. Dashboard provides container management

**Features to Configure**:
- User management
- Stack templates
- Registry credentials
- Webhooks for updates

### Nextcloud

```env
NEXTCLOUD_PORT=8888
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=secure-password
NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.homeserver.local
MYSQL_ROOT_PASSWORD=root-password
MYSQL_PASSWORD=user-password
```

**First Access**:
1. http://localhost:8888
2. Admin credentials from .env
3. Configure trusted domains
4. Set up 2FA (recommended)
5. Install mobile apps

**Important Folders**:
- `/mnt/media` - Media directory
- Personal data - User files
- Shared folders - Team collaboration

### Immich

```env
IMMICH_PORT=2283
IMMICH_API_KEY=generate-in-ui
```

**Features**:
- Photo backup from mobile
- Facial recognition
- Location mapping
- Album organization

### Home Assistant

```env
HOMEASSISTANT_PORT=8123
HOMEASSISTANT_LATITUDE=0.0
HOMEASSISTANT_LONGITUDE=0.0
HOMEASSISTANT_ELEVATION=0
```

**Initial Setup**:
1. Access http://localhost:8123
2. Create account
3. Configure location (for automations)
4. Add integrations (Zigbee, cameras, etc.)
5. Create automations

### Grafana

```env
GRAFANA_PORT=3000
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=secure-password
GRAFANA_DOMAIN=grafana.homeserver.local
```

**Setup Monitoring**:
1. Access http://localhost:3000
2. Default: admin/admin → change to your password
3. Add data sources:
   - Prometheus for metrics
   - InfluxDB for time-series data
4. Import dashboards
5. Create alerts

### Pi-hole (DNS)

```env
PIHOLE_PORT=80
PIHOLE_DNS_PORT=53
PIHOLE_ADMIN_PASSWORD=secure-password
```

**Configuration**:
1. Access http://localhost/admin
2. Set password
3. Configure upstream DNS servers
4. Add blocklists
5. Point router's DNS to Pi-hole IP

### NGINX Proxy Manager

```env
NGINX_PROXY_MANAGER_PORT=81
NGINX_PROXY_MANAGER_SSL_PORT=443
NGINX_PROXY_MANAGER_ADMIN_PORT=81
```

**Initial Setup**:
1. Access http://localhost:81
2. Default: admin@example.com / changeme
3. Add proxy hosts for services
4. Generate SSL certificates
5. Configure access control

## Database Configuration

### PostgreSQL
```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secure-password
```

Used by:
- Hoarder
- Nextcloud (optional)

### MySQL
```env
MYSQL_USER=homeserver
MYSQL_ROOT_PASSWORD=root-password
MYSQL_PASSWORD=user-password
```

Used by:
- Nextcloud (if MariaDB chosen)

### InfluxDB 2.0
```env
INFLUXDB_ADMIN_TOKEN=your-token
INFLUXDB_ORG=homeserver
INFLUXDB_BUCKET=homeserver
```

## Storage Configuration

### Media Paths
```env
VOLUMES_ROOT=/docker-volumes          # Docker named volumes location
MEDIA_PATH=/mnt/media                 # Media directory
BACKUP_PATH=/mnt/backups              # Backup directory
FILE_BROWSER_ROOT=/mnt/media          # File Browser root
```

**Directory Structure**:
```
/mnt/media/
├── downloads/      # qBittorrent/NZBGet downloads
├── movies/         # Radarr organized movies
├── tv/             # Sonarr organized TV shows
├── music/          # Lidarr organized music
└── photos/         # Immich photos
```

### Docker Volumes
Named volumes are created automatically in:
- Linux: `/var/lib/docker/volumes/`
- Docker Desktop: Managed by Docker

## Advanced Configuration

### Custom Domain Names

For local network access:
```bash
# Edit /etc/hosts (Linux/macOS) or C:\Windows\System32\drivers\etc\hosts (Windows)
192.168.1.100 homeserver.local
192.168.1.100 vaultwarden.local
192.168.1.100 nextcloud.local
```

For internet access:
1. Use NGINX Proxy Manager
2. Point domain to your external IP
3. Configure firewall port forwarding
4. Enable SSL with Let's Encrypt

### Resource Limits

Add to services in docker-compose.yml:
```yaml
services:
  service-name:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### Environment-Specific Settings

Create multiple .env files:
```bash
.env.production
.env.staging
.env.development
```

Use with:
```bash
docker compose --env-file .env.production up -d
```

## Security Configuration

### HTTPS/SSL

1. Use NGINX Proxy Manager for automatic SSL
2. Or manually with Let's Encrypt:
   ```bash
   # Install certbot
   sudo apt install certbot
   
   # Generate certificate
   certbot certonly --standalone -d your-domain.com
   ```

### Network Isolation

Services communicate over the `homeserver` network only. To expose externally:
1. Use reverse proxy (NGINX Proxy Manager)
2. Configure firewall rules
3. Use VPN for remote access

### Secrets Management

Store sensitive data in .env:
```env
# Never commit .env to version control
# Add to .gitignore
VAULTWARDEN_ADMIN_TOKEN=xxx
GRAFANA_ADMIN_PASSWORD=xxx
MYSQL_ROOT_PASSWORD=xxx
```

## Configuration Validation

```bash
# Validate docker-compose syntax
docker-compose config

# Check environment variables expanded correctly
docker compose config | grep -A 5 services

# Test service connectivity
docker exec <service> curl http://other-service:port
```

## Troubleshooting Configuration

### Environment variables not applying
```bash
# Ensure .env is in current directory
ls -la .env

# Rebuild without cache
docker compose down
docker compose up -d --build
```

### Database password issues
```bash
# View container environment
docker exec <db-container> env | grep PASSWORD

# Or check logs
docker logs <db-container>
```

### Port conflicts
```bash
# Find what's using a port
lsof -i :<port>  # Linux/macOS
netstat -ano | findstr :<port>  # Windows

# Change port in .env
SERVICE_PORT=9001
```

## Next Steps

1. [Networking and Reverse Proxy Setup](NETWORKING.md)
2. [Security Best Practices](SECURITY.md)
3. [Maintenance and Monitoring](MAINTENANCE.md)

---

**Last Updated**: December 30, 2025
