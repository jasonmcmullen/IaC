# Media Server

Jellyfin, Plex, and media monitoring services.

## Services Included

### Jellyfin
Free and open-source media server compatible with most platforms.

- **Image**: jellyfin/jellyfin:latest
- **Port**: 8096
- **Discovery Port**: 7359
- **GPU**: Optional support (Intel, NVIDIA, VA-API)

Features:
- TV shows and movies
- Music and photos
- Mobile apps for Android/iOS
- Web interface
- Transcoding support
- No account required

### Plex
Premium media server with rich features.

- **Image**: plexinc/pms-docker:latest
- **Port**: 32400
- **Claim Token**: Required for setup
- **Web UI**: Built-in

Features:
- Superior UI/UX
- Better streaming stability
- Live TV support
- Metadata enrichment
- Better platform support
- Cloud backup option

### Tautulli
Monitor and track Plex statistics.

- **Image**: linuxserver/tautulli:latest
- **Port**: 8181
- **Dependency**: Plex server

Features:
- Watch history tracking
- User statistics
- Performance analytics
- Notifications
- Newsletter generation
- Activity monitoring

## Configuration

### Jellyfin Setup
1. Access http://localhost:8096
2. Complete wizard:
   - Language and region
   - Configure media library
   - Configure playback settings
3. Create user accounts
4. Download mobile apps

### Plex Setup
1. Access http://localhost:32400/web
2. Login/create account
3. Claim server with token from .env
4. Add library locations
5. Configure sharing

### Tautulli Setup
1. Access http://localhost:8181
2. Connect to Plex server
3. Create user account
4. Configure notifications
5. Generate statistics

## Media Organization

### Directory Structure
```
/mnt/media/
├── movies/
│   ├── Movie Name (Year)/
│   │   └── Movie Name (Year).mkv
│   └── ...
│
├── tv/
│   ├── TV Show Name/
│   │   ├── Season 01/
│   │   │   └── TV Show Name S01E01.mkv
│   │   └── ...
│   └── ...
│
├── music/
│   ├── Artist Name/
│   │   ├── Album Name/
│   │   │   └── Track Title.mp3
│   │   └── ...
│   └── ...
│
└── photos/
    ├── Year-Month/
    │   └── photos.jpg
    └── ...
```

### Library Configuration
In Jellyfin/Plex:
1. Settings → Libraries
2. Add Library
3. Select content type (Movies, TV, Music, Photos)
4. Browse to folder
5. Configure metadata settings

## Metadata

### Jellyfin Metadata
- Automatic download from online sources
- Manual override support
- Configure in library settings

### Plex Metadata
- Automatic and superior metadata
- Better for large collections
- Manual correction available

## Performance Optimization

### Transcoding
Reduce server load:
1. Limit simultaneous streams
2. Disable transcoding for compatible formats
3. Set quality defaults per user
4. Use hardware acceleration if available

### Library Organization
- Keep naming consistent (Plex requires strict naming)
- Use NFO files for custom metadata
- Organize by content type

### Caching
- Jellyfin: Automatic thumbnail generation
- Plex: Uses local metadata cache
- Both: Improve response times with SSD storage

## Remote Access

### Jellyfin
1. Setup reverse proxy
2. Generate SSL certificate
3. Access from anywhere

### Plex
1. Built-in remote access
2. Enable in settings
3. All traffic through Plex servers
4. More reliable than self-hosted

## Streaming Compatibility

### Jellyfin Clients
- Android
- iOS
- Web
- Roku
- Apple TV
- Fire TV
- Others via third-party apps

### Plex Clients
- Android
- iOS
- Web
- Roku
- Apple TV
- Amazon Fire TV
- Smart TVs (many built-in)
- Best overall compatibility

## Backup and Maintenance

### Backup
```bash
# Backup media locations (if needed)
./scripts/backup.sh

# Backup server configuration
docker exec jellyfin tar czf /data/jellyfin-backup.tar.gz /config
```

### Maintenance
- Regular library scans
- Monitor transcoding performance
- Check disk space
- Update container images regularly

## Troubleshooting

### Jellyfin library not found
```bash
# Verify mount
docker exec jellyfin ls -la /media

# Restart scan
# Go to Settings → Libraries → Refresh
```

### Plex remote access not working
1. Check port forwarding (32400)
2. Verify firewall settings
3. Check Plex account settings
4. Force sign-in on server

### Transcoding issues
```bash
# Check logs
docker logs jellyfin
docker logs plex

# Verify video format
ffprobe video.mkv
```

## Hardware Acceleration

### Intel (Jellyfin)
```yaml
devices:
  - /dev/dri:/dev/dri
environment:
  - JELLYFIN_VAAPI=1
```

### NVIDIA (Jellyfin)
Requires NVIDIA Docker runtime

### AMD/Intel Quicksync
Add to docker-compose:
```yaml
devices:
  - /dev/dri:/dev/dri
```

## Advanced Features

### Jellyfin Plugins
1. Settings → Dashboard → Plugins
2. Browse catalog
3. Install desired plugins
4. Restart server

### Plex Features
- Live TV with tuner
- Cloud sync
- Plex Pass features
- Early access features

## Next Services to Deploy

After media server, consider:
1. **Media Management** - Radarr/Sonarr for automation
2. **Download Clients** - qBittorrent/NZBGet
3. **Overseerr** - User requests for new content
4. **Tautulli** - Enhanced monitoring for Plex

---

**Last Updated**: December 30, 2025
