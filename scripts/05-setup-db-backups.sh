#!/bin/bash
# Fully automated setup for SQLite database backups

set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Validate required environment variables
if [ -z "$APP_NAME" ]; then
  echo "APP_NAME not set — skipping DB backups setup"
  return 0 2>/dev/null || exit 0
fi

if [ -z "$MOUNT_POINT" ]; then
  echo "MOUNT_POINT not set — skipping DB backups setup"
  return 0 2>/dev/null || exit 0
fi

echo "SQLite Database backups system setup..."
echo "Setting up automated backups for /data/$APP_NAME/production.sqlite3"
echo

# Install SQLite3 if not installed
if ! command -v sqlite3 &> /dev/null; then
    echo "SQLite3 not found. Installing..."
    apt-get update
    apt-get install -y sqlite3
    echo "SQLite3 installed successfully."
else
    echo "SQLite3 is already installed."
fi

# Ensure backup source directory exists
if [ ! -d "/data/$APP_NAME" ]; then
    echo "Creating source directory /data/$APP_NAME..."
    mkdir -p "/data/$APP_NAME"
fi

# Create backup directory
echo "Creating backup directory $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"

# Create the backup script with variables populated
echo "Creating backup script..."
cat > /usr/local/bin/backup-$APP_NAME-db.sh << EOF
#!/bin/bash
# SQLite database backup script

# Set variables
APP_NAME="$APP_NAME"
MOUNT_POINT="$MOUNT_POINT"
SOURCE_DB="/data/\$APP_NAME/production.sqlite3"
BACKUP_DIR="\$MOUNT_POINT"
TIMESTAMP=\$(date +"%Y%m%d-%H%M")
BACKUP_FILE="\$BACKUP_DIR/\$APP_NAME-db-backup-\$TIMESTAMP.sqlite3"
LOG_FILE="/var/log/\$APP_NAME-db-backup.log"

# Log function
log_message() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1" | tee -a "\$LOG_FILE"
}

# Verify source database exists
if [ ! -f "\$SOURCE_DB" ]; then
    log_message "Error: Source database \$SOURCE_DB does not exist"
    exit 1
fi

# Make sure backup directory exists
if [ ! -d "\$BACKUP_DIR" ]; then
    mkdir -p "\$BACKUP_DIR"
    if [ \$? -ne 0 ]; then
        log_message "Error: Failed to create backup directory \$BACKUP_DIR"
        exit 1
    fi
    log_message "Created backup directory: \$BACKUP_DIR"
fi

# Create a proper SQLite backup (using sqlite3's .backup command)
log_message "Starting backup of \$SOURCE_DB to \$BACKUP_FILE"

sqlite3 "\$SOURCE_DB" ".backup '\$BACKUP_FILE'"

# Check if backup was successful
if [ \$? -eq 0 ]; then
    log_message "Backup successful: \$BACKUP_FILE"

    # Keep only the 14 most recent backups (1 week worth of backups)
    NUM_DELETED=\$(ls -t "\$BACKUP_DIR"/\$APP_NAME-db-backup-*.sqlite3 2>/dev/null | tail -n +15 | wc -l)
    if [ "\$NUM_DELETED" -gt 0 ]; then
        ls -t "\$BACKUP_DIR"/\$APP_NAME-db-backup-*.sqlite3 | tail -n +15 | xargs rm
        log_message "Cleaned up \$NUM_DELETED old backup(s), keeping 14 most recent files"
    fi
else
    log_message "Error: Backup failed"
    exit 1
fi

exit 0
EOF

# Make the script executable
chmod +x "/usr/local/bin/backup-$APP_NAME-db.sh"

# Create log file
touch "/var/log/$APP_NAME-db-backup.log"
chmod 644 "/var/log/$APP_NAME-db-backup.log"

# Add cron job
echo "Setting up cron job for twice-daily backups..."
CRON_ENTRIES="# Backup $APP_NAME database at 8am and 8pm daily
0 8 * * * /usr/local/bin/backup-$APP_NAME-db.sh
0 20 * * * /usr/local/bin/backup-$APP_NAME-db.sh"

echo "$CRON_ENTRIES" | sudo crontab -
if [ $? -eq 0 ]; then
    echo "Cron jobs added successfully. Current cron jobs:"
    sudo crontab -l
else
    echo "Failed to install cron jobs. Check permissions."
    exit 1
fi

echo "DB backups setup complete!"
echo
echo "To check the status of backups: cat /var/log/$APP_NAME-db-backup.log"
echo "To run a manual backup: sudo /usr/local/bin/backup-$APP_NAME-db.sh"

echo
echo "DB Setup complete!"
echo "✓ SQLite3 installed/verified"
echo "✓ Backup script created at /usr/local/bin/backup-$APP_NAME-db.sh"
echo "✓ Backup directory created at $MOUNT_POINT"
echo "✓ Cron jobs set for 8am and 8pm daily"
echo "✓ Log file created at /var/log/$APP_NAME-db-backup.log"
echo
echo "To check the status of backups: cat /var/log/$APP_NAME-db-backup.log"
echo "To run a manual backup: sudo /usr/local/bin/backup-$APP_NAME-db.sh"
