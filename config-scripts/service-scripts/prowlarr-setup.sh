#!/bin/bash
# Prowlarr Setup Script for Media Server

# Directory structure
SHARED_DIR="/shared"
LOG_FILE="${SHARED_DIR}/prowlarr_setup.log"

# Function to log messages
log() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOG_FILE
}

error() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOG_FILE
}

# Load API keys
if [ -f ${SHARED_DIR}/prowlarr_api.key ]; then
  PROWLARR_API_KEY=$(cat ${SHARED_DIR}/prowlarr_api.key)
else
  error "Prowlarr API key not found"
  exit 1
fi

if [ -f ${SHARED_DIR}/radarr_api.key ]; then
  RADARR_API_KEY=$(cat ${SHARED_DIR}/radarr_api.key)
else
  error "Radarr API key not found"
  exit 1
fi

if [ -f ${SHARED_DIR}/sonarr_api.key ]; then
  SONARR_API_KEY=$(cat ${SHARED_DIR}/sonarr_api.key)
else
  error "Sonarr API key not found"
  exit 1
fi

# Create Prowlarr configuration script
log "Creating Prowlarr configuration script..."
cat > ${SHARED_DIR}/prowlarr_config.sh << 'EOL'
#!/bin/bash
# Wait for Prowlarr to fully start
sleep 30

# Load API keys
PROWLARR_API_KEY=$(cat /shared/prowlarr_api.key)
RADARR_API_KEY=$(cat /shared/radarr_api.key)
SONARR_API_KEY=$(cat /shared/sonarr_api.key)

# Ensure config directory exists
mkdir -p /config/config

# Check if API key is already set in config.xml
if [ -f /config/config.xml ]; then
  if grep -q "<ApiKey>" /config/config.xml; then
    echo "Prowlarr API key already configured"
  else
    # Backup original config
    cp /config/config.xml /config/config.xml.bak
    
    # Insert API key into config
    sed -i "s/<ApiKey><\/ApiKey>/<ApiKey>$PROWLARR_API_KEY<\/ApiKey>/g" /config/config.xml
    
    # If ApiKey tag doesn't exist, add it
    if ! grep -q "<ApiKey>" /config/config.xml; then
      sed -i "s/<Config>/<Config>\n  <ApiKey>$PROWLARR_API_KEY<\/ApiKey>/g" /config/config.xml
    fi
    
    echo "Prowlarr API key configured"
  fi
else
  # Create basic config with API key
  cat > /config/config.xml << EOCFG
<Config>
  <ApiKey>$PROWLARR_API_KEY</ApiKey>
  <AnalyticsEnabled>False</AnalyticsEnabled>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <AuthenticationMethod>Forms</AuthenticationMethod>
</Config>
EOCFG
  echo "Created new Prowlarr config with API key"
fi

# Wait a bit for Prowlarr to initialize fully with the config
sleep 20

# Add Radarr as an application
echo "Adding Radarr application..."
curl -s -X POST "http://localhost:9696/api/v1/applications" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $PROWLARR_API_KEY" \
  -d '{
    "name": "Radarr",
    "syncLevel": "fullSync",
    "implementationName": "Radarr",
    "implementation": "Radarr",
    "configContract": "RadarrSettings",
    "host": "radarr",
    "port": 7878,
    "apiKey": "'"$RADARR_API_KEY"'",
    "baseUrl": "",
    "syncCategories": [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060],
    "tags": []
  }' || echo "Failed to add Radarr application"

# Add Sonarr as an application
echo "Adding Sonarr application..."
curl -s -X POST "http://localhost:9696/api/v1/applications" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $PROWLARR_API_KEY" \
  -d '{
    "name": "Sonarr",
    "syncLevel": "fullSync",
    "implementationName": "Sonarr",
    "implementation": "Sonarr",
    "configContract": "SonarrSettings",
    "host": "sonarr",
    "port": 8989,
    "apiKey": "'"$SONARR_API_KEY"'",
    "baseUrl": "",
    "syncCategories": [5000, 5010, 5020, 5030, 5040, 5045, 5050],
    "tags": []
  }' || echo "Failed to add Sonarr application"

# Add common indexers
echo "Adding common indexers..."

# 1337x
curl -s -X POST "http://localhost:9696/api/v1/indexer" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $PROWLARR_API_KEY" \
  -d '{
    "name": "1337x",
    "implementation": "1337x",
    "configContract": "1337xSettings",
    "implementationName": "1337x",
    "protocol": "torrent",
    "supportsRss": true,
    "supportsSearch": true,
    "tags": []
  }' || echo "Failed to add 1337x indexer"

# YTS
curl -s -X POST "http://localhost:9696/api/v1/indexer" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $PROWLARR_API_KEY" \
  -d '{
    "name": "YTS",
    "implementation": "YTS",
    "configContract": "YTSSettings",
    "implementationName": "YTS",
    "protocol": "torrent",
    "supportsRss": true,
    "supportsSearch": true,
    "tags": []
  }' || echo "Failed to add YTS indexer"

# The Pirate Bay
curl -s -X POST "http://localhost:9696/api/v1/indexer" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $PROWLARR_API_KEY" \
  -d '{
    "name": "The Pirate Bay",
    "implementation": "TPB",
    "configContract": "TPBSettings",
    "implementationName": "The Pirate Bay",
    "protocol": "torrent",
    "supportsRss": true,
    "supportsSearch": true,
    "tags": []
  }' || echo "Failed to add The Pirate Bay indexer"

echo "Prowlarr configuration completed"
EOL

# Make script executable
chmod +x ${SHARED_DIR}/prowlarr_config.sh

log "Prowlarr configuration script created at ${SHARED_DIR}/prowlarr_config.sh"
