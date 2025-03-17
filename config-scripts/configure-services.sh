#!/bin/bash

# Automated Media Server Configuration Script
# This script uses API calls to configure all the containers

# Directory structure
SHARED_DIR="/shared"
CONFIG_DIR="/config-scripts"
LOG_FILE="${SHARED_DIR}/configuration.log"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to log messages
log() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") ${GREEN}[INFO]${NC} $1" | tee -a $LOG_FILE
}

error() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") ${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE
}

warning() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") ${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE
}

# Create directories
mkdir -p ${SHARED_DIR}

# Start logging
log "Starting automated configuration of media server components"

# Initial wait to ensure all services are up
log "Waiting for services to be fully initialized..."
sleep 30

# Get container service names and IPs
log "Gathering container information..."
RADARR_IP="radarr"
SONARR_IP="sonarr"
PROWLARR_IP="prowlarr"
QBIT_IP="qbittorrent"
JELLYFIN_IP="jellyfin"
OVERSEERR_IP="overseerr"
BAZARR_IP="bazarr"
HOMARR_IP="homarr"

# Set default auth details
ADMIN_USER="admin"
ADMIN_PASS="mediaserver123" # Users should change this

# Generate API keys - write to shared volume for inter-container use
RADARR_API_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
SONARR_API_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
PROWLARR_API_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

echo $RADARR_API_KEY > ${SHARED_DIR}/radarr_api.key
echo $SONARR_API_KEY > ${SHARED_DIR}/sonarr_api.key
echo $PROWLARR_API_KEY > ${SHARED_DIR}/prowlarr_api.key

log "Generated API keys for services"

# Configure qBittorrent (preparation for API use)
log "Configuring qBittorrent..."
# Create needed categories
mkdir -p ${SHARED_DIR}/qbit_categories
echo "{\"name\":\"radarr\",\"savePath\":\"/downloads/radarr\"}" > ${SHARED_DIR}/qbit_categories/radarr.json
echo "{\"name\":\"sonarr\",\"savePath\":\"/downloads/sonarr\"}" > ${SHARED_DIR}/qbit_categories/sonarr.json

# Use curl to configure services via API
# Wait for services to be fully ready
sleep 30

# Configure Radarr via API
log "Configuring Radarr..."
# Set API key in config file
mkdir -p ${SHARED_DIR}/radarr
cat > ${SHARED_DIR}/radarr/config.xml << EOL
<Config>
  <ApiKey>${RADARR_API_KEY}</ApiKey>
  <AnalyticsEnabled>False</AnalyticsEnabled>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <AuthenticationMethod>Forms</AuthenticationMethod>
</Config>
EOL

# Configure Sonarr via API
log "Configuring Sonarr..."
# Set API key in config file
mkdir -p ${SHARED_DIR}/sonarr
cat > ${SHARED_DIR}/sonarr/config.xml << EOL
<Config>
  <ApiKey>${SONARR_API_KEY}</ApiKey>
  <AnalyticsEnabled>False</AnalyticsEnabled>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <AuthenticationMethod>Forms</AuthenticationMethod>
</Config>
EOL

# Configure Prowlarr
log "Configuring Prowlarr..."
# Set API key in config file
mkdir -p ${SHARED_DIR}/prowlarr
cat > ${SHARED_DIR}/prowlarr/config.xml << EOL
<Config>
  <ApiKey>${PROWLARR_API_KEY}</ApiKey>
  <AnalyticsEnabled>False</AnalyticsEnabled>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <AuthenticationMethod>Forms</AuthenticationMethod>
</Config>
EOL

# Create Radarr configuration script
log "Creating Radarr configuration script..."
cat > ${SHARED_DIR}/radarr_config.sh << 'EOL'
#!/bin/bash
# This script will be run on Radarr container startup

# Wait for Radarr to be fully up
sleep 60

# Add qBittorrent as download client
curl -X POST "http://localhost:7878/api/v3/downloadclient" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/radarr_api.key)" \
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
  }'

# Add movie library path
curl -X POST "http://localhost:7878/api/v3/rootfolder" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/radarr_api.key)" \
  -d '{
    "path": "/movies"
  }'

# Add quality profile
curl -X POST "http://localhost:7878/api/v3/qualityprofile" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/radarr_api.key)" \
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
  }'
EOL

# Create Sonarr configuration script
log "Creating Sonarr configuration script..."
cat > ${SHARED_DIR}/sonarr_config.sh << 'EOL'
#!/bin/bash
# This script will be run on Sonarr container startup

# Wait for Sonarr to be fully up
sleep 60

# Add qBittorrent as download client
curl -X POST "http://localhost:8989/api/v3/downloadclient" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/sonarr_api.key)" \
  -d '{
    "name": "qBittorrent",
    "protocol": "torrent",
    "implementation": "QBittorrent",
    "configContract": "QBittorrentSettings",
    "host": "qbittorrent",
    "port": 8080,
    "username": "admin",
    "password": "mediaserver123",
    "category": "sonarr",
    "enable": true
  }'

# Add TV library path
curl -X POST "http://localhost:8989/api/v3/rootfolder" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/sonarr_api.key)" \
  -d '{
    "path": "/tv"
  }'

# Add quality profile
curl -X POST "http://localhost:8989/api/v3/qualityprofile" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/sonarr_api.key)" \
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
  }'
EOL

# Create Prowlarr configuration script
log "Creating Prowlarr configuration script..."
cat > ${SHARED_DIR}/prowlarr_config.sh << 'EOL'
#!/bin/bash
# This script will be run on Prowlarr container startup

# Wait for Prowlarr to be fully up
sleep 60

# Add Radarr as an application
curl -X POST "http://localhost:9696/api/v1/applications" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/prowlarr_api.key)" \
  -d '{
    "name": "Radarr",
    "syncLevel": "fullSync",
    "implementationName": "Radarr",
    "implementation": "Radarr",
    "configContract": "RadarrSettings",
    "host": "radarr",
    "port": 7878,
    "apiKey": "'$(cat /shared/radarr_api.key)'",
    "baseUrl": "",
    "syncCategories": [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060],
    "tags": []
  }'

# Add Sonarr as an application
curl -X POST "http://localhost:9696/api/v1/applications" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/prowlarr_api.key)" \
  -d '{
    "name": "Sonarr",
    "syncLevel": "fullSync",
    "implementationName": "Sonarr",
    "implementation": "Sonarr",
    "configContract": "SonarrSettings",
    "host": "sonarr",
    "port": 8989,
    "apiKey": "'$(cat /shared/sonarr_api.key)'",
    "baseUrl": "",
    "syncCategories": [5000, 5010, 5020, 5030, 5040, 5045, 5050],
    "tags": []
  }'

# Add some common indexers
curl -X POST "http://localhost:9696/api/v1/indexer" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $(cat /shared/prowlarr_api.key)" \
  -d '{
    "name": "1337x",
    "implementation": "1337x",
    "configContract": "1337xSettings",
    "implementationName": "1337x",
    "protocol": "torrent",
    "supportsRss": true,
    "supportsSearch": true,
    "tags": []
  }'
EOL

# Create Bazarr configuration script
log "Creating Bazarr configuration script..."
cat > ${SHARED_DIR}/bazarr_config.sh << 'EOL'
#!/bin/bash
# This script will be run on Bazarr container startup

# Wait for Bazarr to be fully up
sleep 60

# Configure Radarr and Sonarr integration
# Bazarr has no documented API, so we'll need to modify config files directly
mkdir -p /config/config
cat > /config/config/config.yaml << EOCFG
general:
  use_dark_theme: True
  use_sonarr: True
  use_radarr: True
radarr:
  url: http://radarr:7878
  apikey: $(cat /shared/radarr_api.key)
  movie_path: /movies
sonarr:
  url: http://sonarr:8989
  apikey: $(cat /shared/sonarr_api.key)
  series_path: /tv
EOCFG
EOL

# Make scripts executable
chmod +x ${SHARED_DIR}/*.sh

# Create Homarr configuration
log "Setting up Homarr Dashboard with widgets for all services..."

# Create Homarr configuration directory if it doesn't exist
mkdir -p ${SHARED_DIR}/homarr_config

# Create Homarr setup script
cat > ${SHARED_DIR}/homarr_setup.sh << 'EOL'
#!/bin/bash

# Wait for API keys to be generated
sleep 60

# Get API keys from files
RADARR_API_KEY=$(cat /shared/radarr_api.key)
SONARR_API_KEY=$(cat /shared/sonarr_api.key)
PROWLARR_API_KEY=$(cat /shared/prowlarr_api.key)

# Replace placeholders in the Homarr config with actual API keys
sed -i "s|{{RADARR_API_KEY}}|${RADARR_API_KEY}|g" /shared/homarr_config/default.json
sed -i "s|{{SONARR_API_KEY}}|${SONARR_API_KEY}|g" /shared/homarr_config/default.json
sed -i "s|{{PROWLARR_API_KEY}}|${PROWLARR_API_KEY}|g" /shared/homarr_config/default.json

# Create directories if they don't exist
mkdir -p /app/data/configs/default

# Copy the config to Homarr's configs directory
cp /shared/homarr_config/default.json /app/data/configs/default/

echo "Homarr dashboard configured with widgets for all services!"
EOL

chmod +x ${SHARED_DIR}/homarr_setup.sh

# Create default board configuration with widgets for all services
cat > ${SHARED_DIR}/homarr_config/default.json << 'EOL'
{
  "name": "Media Server",
  "icon": "grid-3x3",
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
      "url": "http://radarr:7878",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "HEAD",
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
          "apiKey": "{{RADARR_API_KEY}}",
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
      "url": "http://sonarr:8989",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "HEAD",
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
          "apiKey": "{{SONARR_API_KEY}}",
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
      "url": "http://jellyfin:8096",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "HEAD",
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
      "url": "http://qbittorrent:8080",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "HEAD",
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
      "url": "http://prowlarr:9696",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "HEAD",
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
          "apiKey": "{{PROWLARR_API_KEY}}",
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
      "url": "http://overseerr:5055",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "HEAD",
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
      "url": "http://bazarr:6767",
      "behaviour": {
        "isOpeningNewTab": false,
        "externalUrl": ""
      },
      "network": {
        "enabledStatusChecker": true,
        "timeout": 5000,
        "method": "HEAD",
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
EOL
