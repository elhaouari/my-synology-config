#!/bin/bash
# Bazarr Setup Script for Media Server

# Directory structure
SHARED_DIR="/shared"
LOG_FILE="${SHARED_DIR}/bazarr_setup.log"

# Function to log messages
log() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOG_FILE
}

error() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOG_FILE
}

# Load API keys
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

# Create Bazarr configuration script
log "Creating Bazarr configuration script..."
cat > ${SHARED_DIR}/bazarr_config.sh << 'EOL'
#!/bin/bash
# Wait for Bazarr to fully start
sleep 30

# Load API keys
RADARR_API_KEY=$(cat /shared/radarr_api.key)
SONARR_API_KEY=$(cat /shared/sonarr_api.key)

# Ensure config directory exists
mkdir -p /config/config

# Create or update Bazarr configuration
# Since Bazarr doesn't have a documented API, we need to modify the config file directly
echo "Configuring Bazarr settings..."

# Check if config already exists
if [ -f /config/config/config.yaml ]; then
  # Backup existing config
  cp /config/config/config.yaml /config/config/config.yaml.bak
  echo "Backed up existing Bazarr config"
fi

# Create a minimal config file with Radarr and Sonarr integration
cat > /config/config/config.yaml << EOCFG
general:
  use_dark_theme: True
  use_sonarr: True
  use_radarr: True
  
radarr:
  url: http://radarr:7878
  apikey: $RADARR_API_KEY
  movie_path: /movies
  
sonarr:
  url: http://sonarr:8989
  apikey: $SONARR_API_KEY
  series_path: /tv
  
subtitles:
  languages:
    - eng
  providers:
    - opensubtitles
    - subscene
EOCFG

echo "Bazarr configuration completed"
EOL

# Make script executable
chmod +x ${SHARED_DIR}/bazarr_config.sh

log "Bazarr configuration script created at ${SHARED_DIR}/bazarr_config.sh"
