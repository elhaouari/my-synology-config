# Create main directories for Docker configs
mkdir -p /volume1/docker/plex
mkdir -p /volume1/docker/sonarr
mkdir -p /volume1/docker/radarr
mkdir -p /volume1/docker/prowlarr
mkdir -p /volume1/docker/qbittorrent
mkdir -p /volume1/docker/bazarr
mkdir -p /volume1/docker/overseerr

# Create Homarr directories (including the missing one that caused the error)
mkdir -p /volume1/docker/homarr/configs
mkdir -p /volume1/docker/homarr/icons
mkdir -p /volume1/docker/homarr/data

# Create media directories
mkdir -p /volume1/media-server/tv
mkdir -p /volume1/media-server/movies
mkdir -p /volume1/media-server/downloads
