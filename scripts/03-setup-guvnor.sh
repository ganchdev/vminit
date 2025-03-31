#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

# Skip if APP_NAME not set
if [ -z "$APP_NAME" ]; then
    echo "APP_NAME not set — skipping Guvnor setup"
    return 0 2>/dev/null || exit 0
fi

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
TEMPLATE_PATH="$SCRIPT_DIR/templates/service.yaml.template"
OUTPUT_PATH="/etc/guvnor/services/$APP_NAME.yaml"

# Check if output file already exists
if [ -f "$OUTPUT_PATH" ]; then
    echo "Service config already exists at $OUTPUT_PATH — skipping creation"
    return 0 2>/dev/null || exit 0
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

# Confirm the values are exported
echo "Rendering with:"
echo "  APP_NAME=$APP_NAME"
echo "  IMAGE_NAME=$IMAGE_NAME"
echo "  IMAGE_TAG=$IMAGE_TAG"
echo "  APP_HOST=$APP_HOST"

# Verify template exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Error: Template not found at $TEMPLATE_PATH"
    exit 1
fi

# Export variables if not already exported
export APP_NAME IMAGE_NAME IMAGE_TAG APP_HOST

# Perform substitution with explicit variables
envsubst '$APP_NAME $IMAGE_NAME $IMAGE_TAG $APP_HOST' < "$TEMPLATE_PATH" > "$OUTPUT_PATH"
echo "Rendered service file to: $OUTPUT_PATH"

# Verify output
if [ ! -s "$OUTPUT_PATH" ]; then
    echo "Error: Substitution failed - output file is empty"
    exit 1
fi

echo "Guvnor setup completed successfully!"
