#!/bin/bash

echo "Updating package lists..."
apt-get update

if [ "$UPGRADE_PACKAGES" = true ]; then
    echo "Upgrading all packages..."
    apt-get upgrade -y
fi

if [ "$INSTALL_OS_PACKAGES" = true ]; then
    echo "Installing ncdu"
    apt install ncdu
fi
