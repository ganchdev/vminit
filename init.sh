#!/bin/bash

set -e

chmod +x scripts/*.sh

# Script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="${SCRIPT_DIR}/config.env"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

# Banner
echo "================================"
echo "  VM Host Initialization Script "
echo "================================"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    echo "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "Initializing Ubuntu"
echo "================================"

# Execute all scripts in numerical order
for script in $(ls -1 "$SCRIPTS_DIR"/*.sh | sort); do
    echo "Running $(basename "$script")..."
    source "$script"
    echo "--------------------------------"
done

echo "VM initialization completed!"
