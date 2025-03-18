#!/bin/bash

echo "Setting up media server on Synology NAS..."

# Create the required directory structure
echo "Creating directory structure..."
mkdir -p homarr/{configs,icons,data} \
      radarr/config \
      sonarr/config \
      prowlarr/config \
      qbittorrent/config \
      overseerr/config \
      bazarr/config \
      jellyfin/config \
      media/{movies,tv} \
      downloads/{radarr,sonarr,incomplete,complete} \
      shared \
      config-scripts

# Make the script executable
chmod +x config-scripts/main-config-script.sh

# Set proper permissions for Synology
echo "Setting proper permissions..."
chmod -R 777 ./shared

# Start the containers
echo "Starting Docker Compose services..."
export DEFAULT_USER=admin
export DEFAULT_PASSWORD=MediaServer123!
export HOMARR_DEFAULT_EMAIL=admin@example.com
docker-compose up -d

# Wait for everything to be set up
echo "Wait for approximately 5 minutes for complete initialization..."
echo "You can check the status by running: docker logs configurator"

# Determine IP address automatically
IP_ADDRESS=$(ip route get 1 | awk '{print $NF;exit}')
echo ""
echo "========================================================================"
echo "Setup complete! Your media server is now starting."
echo ""
echo "Access your media server at: http://${IP_ADDRESS}:51000"
echo "Default login: admin / password set in docker-compose.yml"
echo ""
echo "IMPORTANT: Please change default passwords after first login"
echo "For detailed access information, check shared/media_server_access.txt"
echo "========================================================================"
