# Media Management

Automated media organization and request management services.

## Services Included

### Radarr
Movie collection manager with automated downloading and organization.

- **Image**: linuxserver/radarr:latest
- **Port**: 7878
- **Purpose**: Automated movie management
- **Integrates**: qBittorrent, Usenet clients, indexers

### Sonarr
TV show collection manager with episode tracking.

- **Image**: linuxserver/sonarr:latest
- **Port**: 8989
- **Purpose**: Automated TV show management
- **Features**: Episode tracking, quality management, release notification

### Lidarr
Music collection manager for artists and albums.

- **Image**: linuxserver/lidarr:latest
- **Port**: 8686
- **Purpose**: Automated music library management
- **Features**: Artist tracking, album management, quality profiles

### Bazarr
Subtitle management and downloading.

- **Image**: linuxserver/bazarr:latest
- **Port**: 6767
- **Purpose**: Automatic subtitle downloading
- **Features**: Movie and TV subtitle management, multiple languages

### Prowlarr
Centralized indexer manager for all *arr applications.

- **Image**: linuxserver/prowlarr:latest
- **Port**: 9696
- **Purpose**: Manage trackers and indexers centrally
- **Benefits**: Single source of indexer configuration

### Overseerr
Request platform for users to discover and request media.

- **Image**: sctx/overseerr:latest
- **Port**: 5055
- **Purpose**: User media discovery and requests
- **Features**: Integration with Radarr/Sonarr for auto-download

## Workflow

```
User Request (Overseerr)
    ↓
Prowlarr (Finds release)
    ↓
Radarr/Sonarr (Downloads via qBittorrent)
    ↓
Bazarr (Finds subtitles)
    ↓
Jellyfin/Plex (Streams to users)
```

## Configuration

### Prowlarr Setup
1. Access http://localhost:9696
2. Add indexers:
   - Public torrent trackers
   - Usenet indexers
   - Scene indexers (if available)
3. Test connectivity
4. Create API key

### Radarr Setup
1. Access http://localhost:7878
2. Settings → Indexers:
   - Add Prowlarr
   - Or add individual indexers
3. Settings → Download Clients:
   - Add qBittorrent
   - Test connection
4. Settings → Quality:
   - Configure quality profiles
5. Root Folders:
   - Point to /movies directory
6. Add movies to monitor

### Sonarr Setup
1. Access http://localhost:8989
2. Same configuration as Radarr:
   - Indexers via Prowlarr
   - qBittorrent client
   - Quality profiles
3. Root Folders:
   - Point to /tv directory
4. Add TV shows

### Lidarr Setup
1. Access http://localhost:8686
2. Configure for music:
   - Root folder: /music
   - Metadata quality
   - Album release types
3. Add artists

### Bazarr Setup
1. Access http://localhost:6767
2. Connect to:
   - Radarr/Sonarr instances
3. Configure languages:
   - English
   - Other languages as needed
4. Set subtitle providers:
   - OpenSubtitles
   - TVsubtitles
   - Other sources

### Overseerr Setup
1. Access http://localhost:5055
2. Plex or Jellyfin connection:
   - Server URL
   - API key
3. Radarr/Sonarr connection:
   - Hostname
   - API keys
   - Quality profiles
4. Create user account
5. Configure rules

## Quality Profiles

### Movies (Radarr)
Example 4K profile:
```
HEVC (h.265) 4K (2160p)
Preferred: 40 Mbps
Minimum: 20 Mbps
```

### TV Shows (Sonarr)
Example HD profile:
```
H.264 (HEVC)
1080p preferred
Minimum 10 Mbps
```

### Music (Lidarr)
```
FLAC format preferred
Minimum bitrate: 320 kbps
```

## Automation Rules

### Radarr - Auto-download newly released movies
1. Settings → Connect
2. Add notification/script
3. Trigger on new movie

### Sonarr - Auto-download new episodes
1. Settings → Connect
2. RSS Feed check every 15 minutes
3. Auto-grab when available

### Overseerr - Auto-download user requests
1. Configure approval rules:
   - Auto-approve for admins
   - Require approval for users
2. Auto-download approved content

## Indexer Management

### Public Torrent Trackers
- The Pirate Bay (TPB)
- 1337x
- Rarbg
- Others

### Usenet Indexers
- NZBGeek
- DrunkenSlug
- Other NZB sites

### Scene Trackers
- Various private trackers
- Requires account/invitation

### Setup via Prowlarr
1. Add indexer
2. Authenticate if needed
3. Test
4. Sync to apps

## Performance Tuning

### Indexer Load
- Don't add too many indexers
- Use Prowlarr to deduplicate
- Monitor CPU usage

### Database Optimization
- Regular backups
- Monitor disk space
- Clean old logs

### Network
- Limit concurrent downloads
- Set bandwidth limits
- Use VPN for downloads (recommended)

## Backup Strategy

Critical volumes:
- radarr-data
- sonarr-data
- lidarr-data
- bazarr-data
- prowlarr-data
- overseerr-data

All contain:
- Configuration
- Watch lists
- Settings

Backup script:
```bash
./scripts/backup.sh
```

## Advanced Features

### Custom Formats (Radarr/Sonarr)
Define preferred releases:
```
Scoring: 50 points for 4K content
       -50 points for CAM releases
```

### Release Profiles
```
Preferred: (1080p|720p)
Ignored: (cam|ts|screener)
```

### Webhook Notifications
Trigger on:
- Grab
- Import
- Upgrade
- Rename
- Delete

## Troubleshooting

### No results found
```bash
# Check Prowlarr indexers
docker logs prowlarr

# Verify connectivity
# Try manual test in Prowlarr
```

### Download not grabbing
```bash
# Check indexers configured
# Verify qBittorrent running
# Check disk space

docker logs radarr
docker logs sonarr
```

### Overseerr not finding content
```bash
# Verify Plex/Jellyfin connection
# Check API key
# Verify Radarr/Sonarr sync

docker logs overseerr
```

### Subtitles not downloading
```bash
# Check Bazarr language settings
# Verify subtitle providers available
# Check file naming (Bazarr expects exact match)

docker logs bazarr
```

## Legal Considerations

⚠️ **Important**: 
- Respect copyright laws in your jurisdiction
- Only download content you have rights to
- Consider content licensing
- Check local regulations

## Deployment Order

1. **Prowlarr** - Indexer management
2. **Radarr** - Movie management
3. **Sonarr** - TV show management
4. **qBittorrent** - Download client
5. **Lidarr** - Music management
6. **Bazarr** - Subtitle management
7. **Overseerr** - User requests

## Integration Points

Works with:
- **Download Clients**: qBittorrent, NZBGet
- **Indexers**: Public, Usenet, Scene
- **Reverse Proxy**: NGINX for remote access
- **Monitoring**: Prometheus/Grafana

## Related Services

- **Download Clients** - qBittorrent, NZBGet
- **Media Server** - Jellyfin, Plex
- **Monitoring** - Prometheus, Grafana

## Alternative Services

- **LazyLibrarian** - Alternative to Lidarr
- **Mylar** - Comic book management
- **Readarr** - Book management (beta)

---

**Last Updated**: December 30, 2025
