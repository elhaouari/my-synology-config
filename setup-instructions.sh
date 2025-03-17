#!/bin/bash

# Create the required directory structure
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

# Copy the configuration script to the config-scripts directory
cat > config-scripts/configure-services.sh << 'EOF'
#!/bin/bash
# Automated configuration script 
# The content of the configuration-script.sh goes here
EOF

# Make the script executable
chmod +x config-scripts/configure-services.sh

# Create the docker-compose.yml file
cat > docker-compose.yml << 'EOF'
# The content of the automated-media-server.yml goes here
EOF

# Start the containers
echo "Starting Docker Compose services..."
docker-compose up -d

# Wait for everything to be set up
echo "Wait for approximately 5 minutes for complete initialization..."
echo "You can check the status by running: docker logs configurator"
echo "Access your media server at: http://YOUR_IP:7575 (Homarr dashboard)"
