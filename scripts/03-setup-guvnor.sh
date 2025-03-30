#!/bin/bash

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate required variables
: "${APP_NAME:?APP_NAME is required}"
: "${IMAGE_NAME:?IMAGE_NAME is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"
: "${APP_HOST:?APP_HOST is required}"

echo "Setting up Guvnor for app: $APP_NAME"

# Install Guvnor
curl -fsSL https://guvnor.k.io/install.sh | sudo bash
guvnor init

# Create app data directory
mkdir -p "/data/$APP_NAME"
chown -R 1000:1000 "/data/$APP_NAME"

# Create system group and user
groupadd --system --gid 1000 guvnor 2>/dev/null || echo "Group already exists"
useradd --system --uid 1000 --gid 1000 --shell /bin/bash guvnor 2>/dev/null || echo "User already exists"

# Ensure envsubst is available
if ! command -v envsubst &> /dev/null; then
    echo "Installing envsubst (gettext-base)..."
    apt-get update && apt-get install -y gettext-base
fi

# Render service template
TEMPLATE_PATH="${SCRIPT_DIR}/../templates/service.yml.template"
OUTPUT_PATH="/etc/guvnor/services/$APP_NAME.yml"
mkdir -p "$(dirname "$OUTPUT_PATH")"

envsubst < "$TEMPLATE_PATH" > "$OUTPUT_PATH"
echo "Rendered template to $OUTPUT_PATH"

echo "Guvnor setup completed successfully!"
