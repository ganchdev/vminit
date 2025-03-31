#!/bin/bash

echo "Updating package lists..."
apt update

if [ "$UPGRADE_PACKAGES" = true ]; then
    echo "Upgrading all packages..."
    apt upgrade -y
fi

if [ "$INSTALL_OS_PACKAGES" = true ]; then
    echo "Installing ncdu"
    apt install ncdu
fi
