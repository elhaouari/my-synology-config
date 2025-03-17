#!/bin/bash
# Improved Homarr Setup Script for Media Server on Synology NAS

# Directory structure
SHARED_DIR="/shared"
LOG_FILE="${SHARED_DIR}/homarr_setup.log"

# Function to log messages
log() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOG_FILE
}

error() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOG_FILE
}

info() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOG_FILE
}

# Synology NAS IP
SYNOLOGY_IP="192.168.1.150"

# Load API keys
if [ -f "${SHARED_DIR}/radarr_api.key" ]; then
  RADARR_API_KEY=$(cat "${SHARED_DIR}/radarr_api.key")
  info "Loaded Radarr API key"
else
  error "Radarr API key not found"
  RADARR_API_KEY="placeholder-generate-proper-api-key"
  info "Using placeholder for Radarr API key"
fi

if [ -f "${SHARED_DIR}/sonarr_api.key" ]; then
  SONARR_API_KEY=$(cat "${SHARED_DIR}/sonarr_api.key")
  info "Loaded Sonarr API key"
else
  error "Sonarr API key not found"
  SONARR_API_KEY="placeholder-generate-proper-api-key"
  info "Using placeholder for Sonarr API key"
fi

if [ -f "${SHARED_DIR}/prowlarr_api.key" ]; then
  PROWLARR_API_KEY=$(cat "${SHARED_DIR}/prowlarr_api.key")
  info "Loaded Prowlarr API key"
else
  error "Prowlarr API key not found"
  PROWLARR_API_KEY="placeholder-generate-proper-api-key"
  info "Using placeholder for Prowlarr API key"
fi

# Create Homarr setup script
log "Creating improved Homarr setup script..."
cat > "${SHARED_DIR}/homarr_setup.sh" << EOF
#!/bin/bash
# Wait for Homarr to start
sleep 30

echo "Setting up Homarr dashboard..."

# Get API keys
RADARR_API_KEY="${RADARR_API_KEY}"
SONARR_API_KEY="${SONARR_API_KEY}"
PROWLARR_API_KEY="${PROWLARR_API_KEY}"

# Get the IP of the host
SYNOLOGY_IP="${SYNOLOGY_IP}"

# Create directory structure
mkdir -p /app/data/configs/
mkdir -p /app/data/configs/default

# Create default configuration for board
cat > /app/data/configs/default.json << EOCFG
{
  "name": "Media Server",
  "icon": "server",
  "backgroundURL": "",
  "primaryColor": {
    "light": "#3d24c6",
    "dark": "#3d24c6"
  },
  "secondaryColor": {
    "light": "#ef52d1",
    "dark": "#ef52d1"
  },
  "paddingTop": 0,
  "shape": "rounded",
  "category": [],
  "apps": [
    {
      "id": "radarr",
      "name": "Radarr",
      "url": "http://\${SYNOLOGY_IP}:51001",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "GET",
        "allowInsecure": false
      },
      "appearance": {
        "iconUrl": "auto",
        "appNameStatus": true,
        "positionAppName": "column",
        "appNameFontSize": 1
      },
      "integration": {
        "type": "radarr",
        "properties": {
          "apiKey": "\${RADARR_API_KEY}",
          "enabled": true
        }
      },
      "area": {
        "type": "app"
      },
      "position": {
        "x": 0,
        "y": 0,
        "width": 5,
        "height": 2
      }
    },
    {
      "id": "sonarr",
      "name": "Sonarr",
      "url": "http://\${SYNOLOGY_IP}:51002",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "GET",
        "allowInsecure": false
      },
      "appearance": {
        "iconUrl": "auto",
        "appNameStatus": true,
        "positionAppName": "column",
        "appNameFontSize": 1
      },
      "integration": {
        "type": "sonarr",
        "properties": {
          "apiKey": "\${SONARR_API_KEY}",
          "enabled": true
        }
      },
      "area": {
        "type": "app"
      },
      "position": {
        "x": 5,
        "y": 0,
        "width": 5,
        "height": 2
      }
    },
    {
      "id": "jellyfin",
      "name": "Jellyfin",
      "url": "http://\${SYNOLOGY_IP}:51007",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "GET",
        "allowInsecure": false
      },
      "appearance": {
        "iconUrl": "auto",
        "appNameStatus": true,
        "positionAppName": "column",
        "appNameFontSize": 1
      },
      "integration": {
        "type": "jellyfin",
        "properties": {
          "enabled": true
        }
      },
      "area": {
        "type": "app"
      },
      "position": {
        "x": 10,
        "y": 0,
        "width": 5,
        "height": 2
      }
    },
    {
      "id": "qbittorrent",
      "name": "qBittorrent",
      "url": "http://\${SYNOLOGY_IP}:51004",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "GET",
        "allowInsecure": false
      },
      "appearance": {
        "iconUrl": "auto",
        "appNameStatus": true,
        "positionAppName": "column",
        "appNameFontSize": 1
      },
      "integration": {
        "type": "qbittorrent",
        "properties": {
          "username": "admin",
          "password": "mediaserver123",
          "enabled": true
        }
      },
      "area": {
        "type": "app"
      },
      "position": {
        "x": 0,
        "y": 2,
        "width": 10,
        "height": 2
      }
    },
    {
      "id": "prowlarr",
      "name": "Prowlarr",
      "url": "http://\${SYNOLOGY_IP}:51003",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "GET",
        "allowInsecure": false
      },
      "appearance": {
        "iconUrl": "auto",
        "appNameStatus": true,
        "positionAppName": "column",
        "appNameFontSize": 1
      },
      "integration": {
        "type": "prowlarr",
        "properties": {
          "apiKey": "\${PROWLARR_API_KEY}",
          "enabled": true
        }
      },
      "area": {
        "type": "app"
      },
      "position": {
        "x": 10,
        "y": 2,
        "width": 5,
        "height": 2
      }
    },
    {
      "id": "overseerr",
      "name": "Overseerr",
      "url": "http://\${SYNOLOGY_IP}:51005",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "GET",
        "allowInsecure": false
      },
      "appearance": {
        "iconUrl": "auto",
        "appNameStatus": true,
        "positionAppName": "column",
        "appNameFontSize": 1
      },
      "integration": {
        "type": "overseerr",
        "properties": {
          "enabled": true
        }
      },
      "area": {
        "type": "app"
      },
      "position": {
        "x": 0,
        "y": 4,
        "width": 5,
        "height": 2
      }
    },
    {
      "id": "bazarr",
      "name": "Bazarr",
      "url": "http://\${SYNOLOGY_IP}:51006",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "GET",
        "allowInsecure": false
      },
      "appearance": {
        "iconUrl": "auto",
        "appNameStatus": true,
        "positionAppName": "column",
        "appNameFontSize": 1
      },
      "area": {
        "type": "app"
      },
      "position": {
        "x": 5,
        "y": 4,
        "width": 5,
        "height": 2
      }
    },
    {
      "id": "calendar-widget",
      "area": {
        "type": "widget",
        "properties": {
          "type": "calendar",
          "properties": {
            "appIdMatches": ["radarr", "sonarr"],
            "hideEmptyDays": false,
            "maxCount": 10,
            "maxFutureDate": 14
          }
        }
      },
      "position": {
        "x": 0,
        "y": 6,
        "width": 5,
        "height": 4
      }
    },
    {
      "id": "download-speed-widget",
      "area": {
        "type": "widget",
        "properties": {
          "type": "downloadSpeed",
          "properties": {
            "appId": "qbittorrent",
            "displayCompact": false
          }
        }
      },
      "position": {
        "x": 5,
        "y": 6,
        "width": 5,
        "height": 2
      }
    },
    {
      "id": "torrents-widget",
      "area": {
        "type": "widget",
        "properties": {
          "type": "torrents",
          "properties": {
            "appId": "qbittorrent",
            "displayCompact": false
          }
        }
      },
      "position": {
        "x": 5,
        "y": 8,
        "width": 5,
        "height": 2
      }
    },
    {
      "id": "overseerr-requests",
      "area": {
        "type": "widget",
        "properties": {
          "type": "overseerr",
          "properties": {
            "appId": "overseerr",
            "view": "requests",
            "hideCompletedRequests": false,
            "maxCount": 5
          }
        }
      },
      "position": {
        "x": 10,
        "y": 4,
        "width": 5,
        "height": 6
      }
    },
    {
      "id": "search-widget",
      "area": {
        "type": "widget",
        "properties": {
          "type": "search",
          "properties": {
            "searchProvider": "search-engine",
            "openingMethod": "newtab"
          }
        }
      },
      "position": {
        "x": 0,
        "y": 10,
        "width": 15,
        "height": 1
      }
    }
  ],
  "sections": []
}
EOCFG

# Ensure the configs directory exists
mkdir -p /app/data/configs/default

# Copy the configuration file to the default location
cp /app/data/configs/default.json /app/data/configs/default/
echo "Config saved to /app/data/configs/default/"

# Create a backup configuration also at the root level
cp /app/data/configs/default.json /app/data/
echo "Backup config saved to /app/data/"

# Set permissions to make sure files are accessible
chmod 644 /app/data/configs/default.json
chmod 644 /app/data/configs/default/default.json
chmod 755 /app/data/configs/default

echo "Homarr dashboard setup completed successfully"
echo "Dashboard accessible at http://\${SYNOLOGY_IP}:51000"
EOF

# Make script executable
chmod +x "${SHARED_DIR}/homarr_setup.sh"

log "Improved Homarr setup script created at ${SHARED_DIR}/homarr_setup.sh"
log "This script will create a dashboard for all media services on http://${SYNOLOGY_IP}:51000"
