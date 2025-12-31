# Networking and Reverse Proxy Setup

Guide for setting up networking, DNS, and secure remote access.

## Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Local Network (192.168.1.x)             │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │        Docker Host (Home Server)                 │   │
│  │        IP: 192.168.1.100                         │   │
│  │                                                  │   │
│  │  ┌────────────────────────────────────────────┐ │   │
│  │  │    Docker Network: homeserver              │ │   │
│  │  │                                            │ │   │
│  │  │  ┌──────────────┐   ┌──────────────────┐ │ │   │
│  │  │  │ File Browser │   │  Vaultwarden     │ │ │   │
│  │  │  │  :8080       │   │  :8000           │ │ │   │
│  │  │  └──────────────┘   └──────────────────┘ │ │   │
│  │  │                                            │ │   │
│  │  │  ┌──────────────┐   ┌──────────────────┐ │ │   │
│  │  │  │ Portainer    │   │  Hoarder         │ │ │   │
│  │  │  │  :9000       │   │  :3000           │ │ │   │
│  │  │  └──────────────┘   └──────────────────┘ │ │   │
│  │  │                                            │ │   │
│  │  └────────────────────────────────────────────┘ │   │
│  │                                                  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
│                    ↑                                      │
│        ┌──────────────────────────┐                     │
│        │ NGINX Proxy Manager      │                     │
│        │ Reverse Proxy            │                     │
│        │ SSL/TLS Termination      │                     │
│        │ Access Control           │                     │
│        └──────────────────────────┘                     │
│                    ↑                                      │
└────────────────────────────────────────────────────────┬─┘
                    Internet
```

## DNS Resolution

### Local DNS (LAN)

#### Option 1: Hosts File
Edit `/etc/hosts` (Linux/macOS) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```hosts
192.168.1.100 homeserver.local
192.168.1.100 vaultwarden.local
192.168.1.100 file-browser.local
192.168.1.100 portainer.local
192.168.1.100 immich.local
192.168.1.100 nextcloud.local
192.168.1.100 grafana.local
192.168.1.100 home-assistant.local
```

#### Option 2: DNS Server (Pi-hole)
```bash
# Deploy Pi-hole
docker compose -f services/dns-and-connections/docker-compose.yml up -d pihole

# Configure router:
# Set Router's DNS to 192.168.1.100
# Pi-hole will resolve local domains
```

#### Option 3: Router Configuration
Configure router's local DNS records:
1. Access router admin panel
2. Create local DNS records for each service
3. Point to home server IP

### Internet DNS

#### Option 1: Cloudflare DDNS
```bash
# For dynamic IP addresses
docker compose -f services/dns-and-connections/docker-compose.yml up -d cloudflare-ddns
```

Configuration:
```env
CLOUDFLARE_API_TOKEN=xxx
CLOUDFLARE_ZONE_ID=xxx
CLOUDFLARE_DNS_RECORDS=example.com
```

#### Option 2: DuckDNS
```bash
# Register at https://www.duckdns.org
# Update IP automatically

docker run -d \
  --name=duckdns \
  -e SUBDOMAINS=mysubdomain \
  -e TOKEN=mytoken \
  -e TZ=UTC \
  linuxserver/duckdns
```

#### Option 3: Static DNS
Point your domain's A record to your home server's public IP:
```
example.com → 1.2.3.4 (your public IP)
```

## NGINX Proxy Manager Setup

### Deploy NGINX Proxy Manager
```bash
cd services/dns-and-connections
docker compose up -d nginx-proxy-manager
```

### Initial Access
1. Visit http://localhost:81
2. Default credentials: admin@example.com / changeme
3. **Change password immediately**

### Configure Proxy Hosts

#### For Local Network
1. Click "Proxy Hosts" → "Add Proxy Host"
2. Configure:
   ```
   Domain Names: vaultwarden.local
   Upstream Host: vaultwarden
   Upstream Port: 80
   ```
3. Skip SSL for local network (optional)
4. Save

#### For Internet Access with SSL
1. Click "Proxy Hosts" → "Add Proxy Host"
2. Configure:
   ```
   Domain Names: vaultwarden.example.com
   Upstream Host: vaultwarden
   Upstream Port: 80
   ```
3. Go to SSL tab:
   - Select "Request a new SSL Certificate"
   - Email: your@email.com
   - I Agree to TOS: checked
   - Save
4. SSL certificate auto-generates in ~1 minute

### Access Control

Restrict access to services:

1. Click "Access Lists"
2. Create new access list:
   ```
   Authorization: Basic Auth
   Add username/password
   ```
3. Apply to proxy host:
   - Edit proxy host
   - Custom Locations tab
   - Add location path
   - Assign access list

### Advanced: Custom Locations

Route specific paths to different services:
```
Domain: example.com
/vaultwarden → vaultwarden:80
/files → file-browser:80
/portainer → portainer:9000
```

Configuration:
1. Edit proxy host
2. Custom Locations tab
3. Add path → select upstream service

## VPN Access (Recommended for Security)

### Option 1: Twingate (Sponsor)
```bash
# Enterprise-grade, peer-to-peer VPN
# Setup guide at: https://www.twingate.com/
```

### Option 2: Tailscale
```bash
# Easy mesh VPN setup

docker run -d \
  --name=tailscale \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -e TAILSCALE_STATE_DIR=/var/lib/tailscale \
  -v /var/lib/tailscale:/var/lib/tailscale \
  ghcr.io/tailscale/tailscale:latest
```

### Option 3: WireGuard
```bash
# Deploy WireGuard VPN
docker compose up -d wireguard

# Access via VPN client
```

## Firewall Configuration

### UFW (Ubuntu Firewall)

```bash
# Enable firewall
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow specific port ranges
sudo ufw allow 8000:9000/tcp

# View rules
sudo ufw status

# Delete rule
sudo ufw delete allow 8000/tcp
```

### Port Forwarding (Router)

For exposing services to internet:

1. Log into router admin panel
2. Find Port Forwarding section
3. Forward:
   - External Port 80 → Local IP 192.168.1.100:80
   - External Port 443 → Local IP 192.168.1.100:443
4. Save and reboot router

**Security**: Only forward HTTPS (443) for security

## SSL/TLS Certificates

### Automatic (Recommended)
NGINX Proxy Manager handles Let's Encrypt automatically:
1. Create proxy host
2. Enable SSL
3. Request new certificate
4. Auto-renewal handled

### Manual with Certbot
```bash
# Install certbot
sudo apt install certbot

# Generate certificate
sudo certbot certonly --standalone \
  -d example.com \
  -d vaultwarden.example.com

# Location: /etc/letsencrypt/live/example.com/

# Renewal (automatic)
sudo systemctl enable certbot.timer
```

## Network Isolation

### Isolate Services
Separate critical services on isolated networks:

```yaml
networks:
  vaultwarden-only:
    driver: bridge
  public-services:
    driver: bridge

services:
  vaultwarden:
    networks:
      - vaultwarden-only
  
  nginx-proxy:
    networks:
      - public-services
```

### Disable External Access
Services internal-only by default:
- Only expose through reverse proxy
- Don't map ports directly
- Use internal network only

## Bandwidth and QoS

### Docker Bridge Bandwidth Limiting
```bash
# Limit service bandwidth
docker network create \
  --driver=bridge \
  --opt "com.docker.network.bridge.name"="docker0" \
  --opt "com.docker.driver.mtu"=1500 \
  homeserver
```

### Router QoS
1. Configure router QoS settings
2. Prioritize critical services
3. Limit bandwidth for specific devices

## IPv6 Support

Enable IPv6 in docker-compose:
```yaml
networks:
  homeserver:
    driver: bridge
    ipam:
      config:
        - subnet: 2001:db8::/32
```

## Troubleshooting Network Issues

### Can't reach services externally
```bash
# Check port forwarding
lsof -i :80
lsof -i :443

# Check NGINX Proxy Manager logs
docker logs nginx-proxy-manager

# Verify DNS resolution
nslookup example.com
dig example.com

# Test connectivity
curl -v http://example.com
```

### Slow network performance
```bash
# Check Docker network
docker network inspect homeserver

# Monitor bandwidth
iftop
nethogs

# Check Docker bridge MTU
ip link show docker0
```

### SSL certificate issues
```bash
# Check certificate validity
openssl s_client -connect example.com:443

# View NGINX logs
docker logs nginx-proxy-manager

# Force renewal
docker exec nginx-proxy-manager \
  npm --loglevel=debug install
```

## Security Best Practices

1. **Always use HTTPS** for internet access
2. **Change default passwords** for all services
3. **Enable access control** on sensitive services
4. **Use firewall** to restrict access
5. **Keep domains updated** with dynamic DNS
6. **Monitor logs** for suspicious activity
7. **Use strong certificates** (Let's Encrypt or paid)
8. **Implement rate limiting** on public services
9. **Regular backups** before exposing services
10. **Use VPN** for sensitive operations

## Monitoring Network Activity

```bash
# Monitor traffic
vnstat
nethogs
iftop

# Check open ports
netstat -tuln
ss -tuln

# Monitor Docker network
docker stats
```

## Advanced Networking

### Multiple Networks per Service
```yaml
services:
  service:
    networks:
      - frontend
      - backend
```

### Network Policy
Define which services can communicate:
- vaultwarden: Only NGINX proxy
- Databases: Only applications
- File browser: Only internal network

### Load Balancing
Multiple instances with load balancing:
```yaml
version: '3.8'
services:
  # Multiple file-browser instances
  file-browser-1:
    ...
  file-browser-2:
    ...
  
  # Load balancer
  nginx-lb:
    image: nginx:latest
    ports:
      - "8080:80"
```

## Testing Network Configuration

```bash
# Test local DNS resolution
nslookup homeserver.local
ping homeserver.local

# Test service connectivity
curl http://vaultwarden.local

# Test reverse proxy
curl https://example.com

# Test firewall rules
telnet localhost 443
curl -v https://your-domain.com
```

---

**Last Updated**: December 30, 2025
