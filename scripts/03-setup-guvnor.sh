#!/bin/bash
set -e  # Exit immediately if a command exits with non-zero status

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load config if running standalone (not from init.sh)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    CONFIG_FILE="${SCRIPT_DIR}/../config.env"
    if [ -f "$CONFIG_FILE" ]; then
        echo "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        echo "Warning: Configuration file not found: $CONFIG_FILE"
    fi
fi

# Download and initialize guvnor
curl https://guvnor.k.io/install.sh | sudo bash
guvnor init

# Check if APP_NAME is provided
if [ -n "$APP_NAME" ]; then
    echo "Creating app data directory"
    mkdir -p /data/$APP_NAME
else
    echo "Error: APP_NAME environment variable is required"
    echo "Usage: APP_NAME=myapp $0"
    exit 1
fi

# Create group and user
groupadd --system --gid 1000 guvnor || echo "Group already exists"
useradd guvnor --uid 1000 --gid 1000 --shell /bin/bash || echo "User already exists"

# Set ownership for app directory
chown -R 1000:1000 /data/$APP_NAME

render_template() {
    local template="$1"
    local output="$2"

    # Check if envsubst is installed
    if ! command -v envsubst &> /dev/null; then
        echo "envsubst is not installed. Installing gettext package..."
        apt-get update && apt-get install -y gettext-base
    fi

    # Create directory for output file if it doesn't exist
    mkdir -p "$(dirname "$output")"

    # Render the template
    envsubst < "$template" > "$output"
    echo "Template rendered: $output"
}

# Use proper path for template
TEMPLATE_PATH="${SCRIPT_DIR}/../templates/service.yml.template"
render_template "$TEMPLATE_PATH" "/etc/guvnor/service/$APP_NAME.yml"

echo "Setup completed successfully!"
