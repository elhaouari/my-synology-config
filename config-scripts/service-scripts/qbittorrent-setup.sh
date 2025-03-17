#!/bin/bash
# qBittorrent Setup Script for Media Server

# Directory structure
SHARED_DIR="/shared"
LOG_FILE="${SHARED_DIR}/qbittorrent_setup.log"

# Function to log messages
log() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOG_FILE
}

error() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOG_FILE
}

# Create qBittorrent configuration script
log "Creating qBittorrent configuration script..."
cat > ${SHARED_DIR}/qbittorrent_config.sh << 'EOL'
#!/bin/bash
# Wait for qBittorrent to fully start
sleep 30

echo "Configuring qBittorrent..."

# Create directories for categories
mkdir -p /downloads/radarr
mkdir -p /downloads/sonarr
mkdir -p /downloads/completed
mkdir -p /downloads/incomplete

# First, let's log in and get the cookie
SID=$(curl -s -i -X POST http://localhost:8080/api/v2/auth/login \
  --data "username=admin&password=adminadmin" | grep -oP 'SID=\K[^;]+')

if [ -z "$SID" ]; then
  echo "Failed to log in to qBittorrent with default credentials, trying new password..."
  
  # Try with the new password
  SID=$(curl -s -i -X POST http://localhost:8080/api/v2/auth/login \
    --data "username=admin&password=mediaserver123" | grep -oP 'SID=\K[^;]+')
    
  if [ -z "$SID" ]; then
    echo "Failed to log in to qBittorrent. Skipping configuration."
    exit 1
  fi
fi

echo "Successfully logged in to qBittorrent"

# If we got here using the default credentials, change the password
if [ "$SID" != "" ]; then
  echo "Changing qBittorrent password..."
  curl -s -X POST http://localhost:8080/api/v2/app/setPreferences \
    --cookie "SID=$SID" \
    --data "json={\"web_ui_password_hash\": \"$(echo -n mediaserver123 | md5sum | awk '{print $1}')\", \"web_ui_password_salt\": \"\"}"
fi

# Configure download paths
echo "Setting up download paths..."
curl -s -X POST http://localhost:8080/api/v2/app/setPreferences \
  --cookie "SID=$SID" \
  --data "json={\"download_path\": \"/downloads/incomplete\", \"save_path\": \"/downloads/completed\"}"

# Add categories for Radarr and Sonarr
echo "Adding download categories..."
curl -s -X POST http://localhost:8080/api/v2/torrents/createCategory \
  --cookie "SID=$SID" \
  --data "category=radarr&savePath=/downloads/radarr"

curl -s -X POST http://localhost:8080/api/v2/torrents/createCategory \
  --cookie "SID=$SID" \
  --data "category=sonarr&savePath=/downloads/sonarr"

# Set other useful qBittorrent settings
echo "Configuring additional qBittorrent settings..."
curl -s -X POST http://localhost:8080/api/v2/app/setPreferences \
  --cookie "SID=$SID" \
  --data "json={
    \"autorun_enabled\": false,
    \"preallocate_all\": true,
    \"incomplete_files_ext\": true,
    \"auto_delete_mode\": 1,
    \"max_ratio_enabled\": true,
    \"max_ratio\": 2,
    \"max_seeding_time_enabled\": true,
    \"max_seeding_time\": 86400,
    \"queueing_enabled\": true,
    \"max_active_downloads\": 5,
    \"max_active_torrents\": 10,
    \"max_active_uploads\": 5,
    \"dont_count_slow_torrents\": true,
    \"add_trackers_enabled\": false,
    \"add_trackers\": \"\",
    \"dht\": true,
    \"pex\": true,
    \"lsd\": true,
    \"encryption\": 0,
    \"web_ui_address\": \"0.0.0.0\",
    \"web_ui_port\": 8080,
    \"bypass_local_auth\": false,
    \"bypass_auth_subnet_whitelist_enabled\": false,
    \"alt_dl_limit\": 5120,
    \"alt_up_limit\": 1024,
    \"scheduler_enabled\": true,
    \"schedule_from_hour\": 1,
    \"schedule_from_min\": 0,
    \"schedule_to_hour\": 8,
    \"schedule_to_min\": 0,
    \"scheduler_days\": 127
  }"

echo "qBittorrent configuration completed"
EOL

# Make script executable
chmod +x ${SHARED_DIR}/qbittorrent_config.sh

log "qBittorrent configuration script created at ${SHARED_DIR}/qbittorrent_config.sh"
