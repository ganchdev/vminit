#!/bin/bash
# Script to mount an NFS share with required environment variables
# Usage: NFS_SERVER="server:/path" MOUNT_POINT="/mnt/destination" ./mount-nfs.sh

set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

# Validate required environment variables
if [ -z "$NFS_SERVER" ]; then
  echo "NFS_SERVER not set — skipping NFS mount setup"
  return 0 2>/dev/null || exit 0
fi

if [ -z "$MOUNT_POINT" ]; then
  echo "MOUNT_POINT not set — skipping NFS mount setup"
  return 0 2>/dev/null || exit 0
fi

# Optional environment variables
MOUNT_OPTIONS=${MOUNT_OPTIONS:-"rw,relatime,vers=3"}
MAKE_PERSISTENT=${MAKE_PERSISTENT:-"false"}

# Display configuration
echo "Mounting NFS with configuration:"
echo "  Server: $NFS_SERVER"
echo "  Mount Point: $MOUNT_POINT"
echo "  Mount Options: $MOUNT_OPTIONS"
echo "  Make Persistent: $MAKE_PERSISTENT"
echo ""

# Check if NFS client is installed
if ! dpkg -l | grep -q "nfs-common"; then
  echo "Installing NFS client..."
  apt-get update
  apt-get install -y nfs-common
fi

# Create mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
  echo "Creating mount point directory: $MOUNT_POINT"
  mkdir -p "$MOUNT_POINT"
fi

# Check if already mounted
if mount | grep -q "$MOUNT_POINT"; then
  echo "NFS share is already mounted at $MOUNT_POINT"
  echo "Current mounts:"
  mount | grep nfs
  echo "...skipping..."
  return 0 2>/dev/null || exit 0
fi

# Mount the NFS share
echo "Mounting NFS share..."
mount -t nfs -o "$MOUNT_OPTIONS" "$NFS_SERVER" "$MOUNT_POINT"

# Verify mount was successful
if mount | grep -q "$MOUNT_POINT"; then
  echo "NFS share successfully mounted at $MOUNT_POINT"
  echo "Mount details:"
  df -h "$MOUNT_POINT"
else
  echo "Failed to mount NFS share"
  exit 1
fi

# Make persistent if requested
if [ "$MAKE_PERSISTENT" = "true" ]; then
  echo "Adding entry to /etc/fstab for persistence..."

  # Check if entry already exists
  if grep -q "$NFS_SERVER $MOUNT_POINT" /etc/fstab; then
    echo "Entry already exists in /etc/fstab"
  else
    echo "$NFS_SERVER $MOUNT_POINT nfs $MOUNT_OPTIONS 0 0" >> /etc/fstab
    echo "Added entry to /etc/fstab"
  fi
fi

echo "NFS mount setup complete!"
