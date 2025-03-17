#!/bin/bash
# Jellyfin Setup Script for Media Server

# Directory structure
SHARED_DIR="/shared"
LOG_FILE="${SHARED_DIR}/jellyfin_setup.log"

# Function to log messages
log() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOG_FILE
}

error() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOG_FILE
}

# Create Jellyfin configuration script
log "Creating Jellyfin configuration script..."
cat > ${SHARED_DIR}/jellyfin_config.sh << 'EOL'
#!/bin/bash
# Wait for Jellyfin to fully start
sleep 30

echo "Jellyfin configuration started"

# Create /config/network.xml if it doesn't exist to configure network settings
if [ ! -f /config/network.xml ]; then
  echo "Setting up Jellyfin network configuration..."
  
  cat > /config/network.xml << EOCFG
<?xml version="1.0" encoding="utf-8"?>
<NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <RequireHttps>false</RequireHttps>
  <EnableIPV6>false</EnableIPV6>
  <EnableIPV4>true</EnableIPV4>
  <EnableUDPBroadcast>true</EnableUDPBroadcast>
  <AutoDiscovery>true</AutoDiscovery>
  <RemoteIPFilter />
  <EnableUPnP>false</EnableUPnP>
  <PublicPort>8096</PublicPort>
  <UPnPCreateHttpPortMap>true</UPnPCreateHttpPortMap>
  <HTTPServerPortNumber>8096</HTTPServerPortNumber>
  <HttpsPortNumber>8920</HttpsPortNumber>
  <EnableHttps>false</EnableHttps>
  <PublicHttpsPort>8920</PublicHttpsPort>
  <EnableIPV6>false</EnableIPV6>
  <PublicIPv6Address />
  <HttpsPortNumber>8920</HttpsPortNumber>
  <EnableHttps>false</EnableHttps>
</NetworkConfiguration>
EOCFG
  
  echo "Jellyfin network configuration created"
fi

# Pre-create some basic settings for Jellyfin
# Create or ensure the movies library folder exists
mkdir -p /data/movies

# Create or ensure the TV shows library folder exists
mkdir -p /data/tv

echo "Jellyfin configuration completed"
EOL

# Make script executable
chmod +x ${SHARED_DIR}/jellyfin_config.sh

log "Jellyfin configuration script created at ${SHARED_DIR}/jellyfin_config.sh"
