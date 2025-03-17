#!/bin/bash
# Radarr Setup Script for Media Server

# Directory structure
SHARED_DIR="/shared"
LOG_FILE="${SHARED_DIR}/radarr_setup.log"

# Function to log messages
log() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOG_FILE
}

error() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOG_FILE
}

# Load API key
if [ -f ${SHARED_DIR}/radarr_api.key ]; then
  RADARR_API_KEY=$(cat ${SHARED_DIR}/radarr_api.key)
else
  error "Radarr API key not found"
  exit 1
fi

# Create Radarr configuration script
log "Creating Radarr configuration script..."
cat > ${SHARED_DIR}/radarr_config.sh << 'EOL'
#!/bin/bash
# Wait for Radarr to fully start
sleep 30

# Load API key
RADARR_API_KEY=$(cat /shared/radarr_api.key)

# Ensure config directory exists
mkdir -p /config/config

# Check if API key is already set in config.xml
if [ -f /config/config.xml ]; then
  if grep -q "<ApiKey>" /config/config.xml; then
    echo "Radarr API key already configured"
  else
    # Backup original config
    cp /config/config.xml /config/config.xml.bak
    
    # Insert API key into config
    sed -i "s/<ApiKey><\/ApiKey>/<ApiKey>$RADARR_API_KEY<\/ApiKey>/g" /config/config.xml
    
    # If ApiKey tag doesn't exist, add it
    if ! grep -q "<ApiKey>" /config/config.xml; then
      sed -i "s/<Config>/<Config>\n  <ApiKey>$RADARR_API_KEY<\/ApiKey>/g" /config/config.xml
    fi
    
    echo "Radarr API key configured"
  fi
else
  # Create basic config with API key
  cat > /config/config.xml << EOCFG
<Config>
  <ApiKey>$RADARR_API_KEY</ApiKey>
  <AnalyticsEnabled>False</AnalyticsEnabled>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <AuthenticationMethod>Forms</AuthenticationMethod>
</Config>
EOCFG
  echo "Created new Radarr config with API key"
fi

# Wait a bit for Radarr to initialize fully with the config
sleep 20

# Add qBittorrent as download client using API
echo "Configuring qBittorrent as download client..."
curl -s -X POST "http://localhost:7878/api/v3/downloadclient" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $RADARR_API_KEY" \
  -d '{
    "name": "qBittorrent",
    "protocol": "torrent",
    "implementation": "QBittorrent",
    "configContract": "QBittorrentSettings",
    "host": "qbittorrent",
    "port": 8080,
    "username": "admin",
    "password": "mediaserver123",
    "category": "radarr",
    "enable": true
  }' || echo "Failed to add qBittorrent download client"

# Add movie library path
echo "Configuring movie library path..."
curl -s -X POST "http://localhost:7878/api/v3/rootfolder" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $RADARR_API_KEY" \
  -d '{
    "path": "/movies"
  }' || echo "Failed to add movie library path"

# Add quality profile
echo "Configuring quality profile..."
curl -s -X POST "http://localhost:7878/api/v3/qualityprofile" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $RADARR_API_KEY" \
  -d '{
    "name": "HD-1080p",
    "upgradeAllowed": true,
    "cutoff": 9,
    "items": [
      {
        "quality": {
          "id": 9,
          "name": "HDTV-1080p",
          "source": "television",
          "resolution": 1080
        },
        "allowed": true
      }
    ]
  }' || echo "Failed to add quality profile"

echo "Radarr configuration completed"
EOL

# Make script executable
chmod +x ${SHARED_DIR}/radarr_config.sh

log "Radarr configuration script created at ${SHARED_DIR}/radarr_config.sh"
