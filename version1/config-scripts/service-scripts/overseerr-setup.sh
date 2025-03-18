#!/bin/bash
# Overseerr Setup Script for Media Server

# Directory structure
SHARED_DIR="/shared"
LOG_FILE="${SHARED_DIR}/overseerr_setup.log"

# Function to log messages
log() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a $LOG_FILE
}

error() {
  echo -e "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a $LOG_FILE
}

# Create Overseerr configuration script
log "Creating Overseerr configuration script..."
cat > ${SHARED_DIR}/overseerr_config.sh << 'EOL'
#!/bin/bash
# Wait for Overseerr to fully start
sleep 60

echo "Configuring Overseerr..."

# Base directory for configuration
CONFIG_DIR="/config"
mkdir -p "$CONFIG_DIR"

# Check if Overseerr is already configured
if [ -f "$CONFIG_DIR/db/db.sqlite3" ]; then
  echo "Overseerr appears to be already configured. Skipping initial setup."
  exit 0
fi

# Create a settings file with pre-configured admin user
mkdir -p "$CONFIG_DIR/settings"

# This is a basic template to start with - Overseerr will replace this
# during first run, but it helps with pre-configuration
cat > "$CONFIG_DIR/settings/settings.json" << EOF
{
  "initialized": false,
  "apiKey": "",
  "applicationTitle": "Overseerr",
  "applicationUrl": "",
  "hideAvailable": false,
  "defaultPermissions": 2,
  "region": "US",
  "originalLanguage": "en",
  "trustProxy": false,
  "skipExistingCheck": false
}
EOF

# Create a SQLite command file to pre-create the admin user
cat > "$CONFIG_DIR/create_admin.sql" << EOF
CREATE TABLE IF NOT EXISTS "user" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "email" varchar NOT NULL,
    "username" varchar NOT NULL,
    "plexId" integer,
    "plexUsername" varchar,
    "permissions" integer NOT NULL DEFAULT 0,
    "avatar" varchar,
    "createdAt" datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "password" varchar,
    "userType" integer NOT NULL DEFAULT 1,
    "plex_token" varchar
);

-- Pre-create admin user (password hash for MediaServer123!)
INSERT OR IGNORE INTO "user" (email, username, permissions, password, userType)
VALUES ('admin@example.com', 'admin', 2, '\$2b\$10\$mxSpGKGMDvf9KAHRJ8YUwOjZjFpGhB4SRN3GWnwASTzWFm0KmaSPm', 1);
EOF

# Using SQLite to create the user
mkdir -p "$CONFIG_DIR/db"
sqlite3 "$CONFIG_DIR/db/db.sqlite3" < "$CONFIG_DIR/create_admin.sql"

echo "Overseerr configuration completed with pre-created admin user"
echo "Username: ${DEFAULT_USER}"
echo "Password: ${DEFAULT_PASSWORD}"
echo "You can now log in to Overseerr using these credentials"
EOL

# Make script executable
chmod +x ${SHARED_DIR}/overseerr_config.sh

log "Overseerr configuration script created at ${SHARED_DIR}/overseerr_config.sh"