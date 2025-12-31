# Download Clients

Torrent and Usenet download management services.

## Services Included

### qBittorrent
Open-source BitTorrent client with web UI.

- **Image**: linuxserver/qbittorrent:latest
- **Port**: 6881 (peer), 8200 (web)
- **Features**: Torrent management, RSS feeds, VPN support
- **Default**: admin/adminpass

### NZBGet
Usenet client for downloading from Usenet servers.

- **Image**: linuxserver/nzbget:latest
- **Port**: 6789
- **Purpose**: Fast Usenet downloading
- **Features**: NZB management, post-processing

## Configuration

### qBittorrent Setup
1. Access http://localhost:8200
2. Default: admin/adminpass
3. **Change password immediately**
4. Settings:
   - Connection port: 6881
   - BitTorrent port ranges
   - Download location
5. Configure VPN (recommended)

### NZBGet Setup
1. Access http://localhost:6789
2. Default: nzbget/tegbzn6789
3. **Change password immediately**
4. Configure:
   - Usenet server details
   - Download directory
   - Post-processing scripts

## Download Management

### qBittorrent Categories
Organize downloads:
```
radarr-movies     → /downloads/movies
sonarr-tv         → /downloads/tv
general           → /downloads
```

### NZBGet Categories
```
radarr-movies     → /downloads/movies
sonarr-tv         → /downloads/tv
```

## VPN Setup (Critical)

⚠️ **Highly Recommended**: Use VPN for all downloads

### qBittorrent with VPN
Docker Compose with gluetun VPN:
```yaml
qbittorrent:
  image: linuxserver/qbittorrent
  network_mode: "service:gluetun"
  depends_on:
    - gluetun

gluetun:
  image: qmcgaw/gluetun
  environment:
    - VPN_SERVICE_PROVIDER=airvpn
    - VPN_USERNAME=xxx
    - VPN_PASSWORD=xxx
```

## Integration with Media Management

### Radarr → qBittorrent
1. Radarr settings → Download Clients
2. Add qBittorrent:
   - Host: qbittorrent
   - Port: 8200
   - Username: admin
   - Password: (your password)
3. Test connection

### Sonarr → qBittorrent
Same process as Radarr configuration.

### Overseerr → Radarr/Sonarr → qBittorrent
Auto-download user requests:
1. Overseerr approves request
2. Radarr/Sonarr adds torrent
3. qBittorrent downloads automatically

## RSS Feed Configuration

### qBittorrent RSS
1. Settings → RSS Reader
2. Add feed URLs
3. Configure rules:
   - Match patterns
   - Save location
   - Auto-download

### Common Feeds
- TorrentFreak RSS
- Public torrent site feeds
- Scene release feeds

## Performance Optimization

### Bandwidth Limiting
Prevent network congestion:
```
Queueing settings:
- Max active downloads: 3
- Max active uploads: 5
- Upload rate limit: 50 kB/s
```

### Resource Management
Monitor in qBittorrent/NZBGet:
- Upload/Download speeds
- Active connections
- CPU usage
- Memory usage

## Security Considerations

### Encryption
- Enable protocol encryption in qBittorrent
- Use VPN tunnel
- Never expose directly to internet

### Privacy
- Use separate VPN for all downloads
- Enable PEX/DHT carefully
- Consider IP binding

## Post-Processing

### qBittorrent - Move completed downloads
```bash
# Category save path: /downloads/movies
# Radarr/Sonarr monitor this folder
# Auto-import when torrent finishes
```

### NZBGet - Post-processing scripts
1. Settings → Post-processing Scripts
2. Add custom scripts
3. Run on download completion

## Advanced Features

### qBittorrent
- Torrent creation
- Selective downloading
- Advanced search
- IP filtering
- Scheduled bandwidth

### NZBGet
- Parallel downloading
- RAR unpacking
- Duplicate removal
- Email notifications
- Scheduled tasks

## Troubleshooting

### No downloads in Radarr/Sonarr
```bash
# Check qBittorrent running
docker ps | grep qbittorrent

# Verify connection in Radarr/Sonarr settings
# Test connection

# Check qBittorrent logs
docker logs qbittorrent
```

### Slow speeds
```bash
# Check bandwidth limits
# qBittorrent → Settings → Speed

# Monitor connections
# qBittorrent → Peers

# Check VPN connection (if used)
```

### VPN not working
```bash
# Verify gluetun running
docker logs gluetun

# Check VPN credentials
# Test VPN connection

# Restart containers
docker restart qbittorrent
```

### Download not importing to Radarr/Sonarr
```bash
# Check category configured
# Verify folder permissions
# Ensure save path correct

# Test manual import
# Radarr/Sonarr → Add files manually
```

## Monitoring Downloads

### qBittorrent Web UI
- Real-time download status
- Peer information
- Speed graphs
- Activity log

### Radarr/Sonarr History
Track completed imports:
1. History tab
2. View grabbed/imported items
3. Check for errors

### Grafana Monitoring
Track statistics:
- Total downloads
- Download speed
- Upload speed
- Activity over time

## Legal and Ethical Usage

⚠️ **Important**:
- Only download content you have rights to
- Respect copyright laws
- Consider using legal services:
  - Netflix
  - Disney+
  - Plex
  - Tubi
- Use VPN responsibly

## Storage Management

### Disk Space Monitoring
```bash
# Check folder sizes
du -sh /downloads/*

# Monitor in Radarr/Sonarr:
# Settings → Folders
```

### Cleanup Strategy
1. Set seeding ratio limits
2. Auto-remove completed after X days
3. Monitor free space
4. Archive old torrents

## Related Services

- **Radarr/Sonarr** - Uses for downloads
- **Overseerr** - Triggers downloads
- **Prowlarr** - Provides indexers
- **Monitoring** - Track download activity

## Alternative Clients

- **Transmission** - Lighter alternative to qBittorrent
- **ruTorrent** - Alternative web UI for rtorrent
- **Deluge** - Alternative torrent client
- **SABnzbd** - Alternative Usenet client

---

**Last Updated**: December 30, 2025
