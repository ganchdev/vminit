#!/bin/bash

set -e

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

# Create new user from env vars
if [ -n "$NEW_USER" ] && [ -n "$NEW_USER_PASSWORD" ]; then
    echo "Ensuring user '$NEW_USER' exists..."

    if id "$NEW_USER" &>/dev/null; then
        echo "User '$NEW_USER' already exists, skipping creation."
    else
        useradd -m -s /bin/bash "$NEW_USER"
        echo "$NEW_USER:$NEW_USER_PASSWORD" | chpasswd
        usermod -aG sudo "$NEW_USER"
        echo "User '$NEW_USER' created and added to sudo group."
    fi
else
    echo "NEW_USER or NEW_USER_PASSWORD not set. Skipping user creation."
fi

# Copy root's SSH keys to new user
if [ -n "$NEW_USER" ] && [ -d /root/.ssh ]; then
    AUTH_KEYS="/home/$NEW_USER/.ssh/authorized_keys"
    ROOT_KEYS="/root/.ssh/authorized_keys"

    mkdir -p /home/$NEW_USER/.ssh

    if [ -f "$AUTH_KEYS" ] && grep -qf "$ROOT_KEYS" "$AUTH_KEYS"; then
        echo "SSH keys already present for $NEW_USER. Skipping copy."
    else
        echo "Copying SSH keys to $NEW_USER..."
        cp "$ROOT_KEYS" "$AUTH_KEYS"
        chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
        chmod 700 /home/$NEW_USER/.ssh
        chmod 600 "$AUTH_KEYS"
    fi
else
    echo "Skipping SSH key copy (either NEW_USER unset or /root/.ssh missing)."
fi

# Harden SSH configuration
echo "Cleaning all existing SSH config overrides..."
rm -f /etc/ssh/sshd_config.d/*.conf

SSH_OVERRIDE="/etc/ssh/sshd_config.d/99-vminit.conf"

echo "Writing new SSH override to $SSH_OVERRIDE..."
cat <<EOF | sudo tee "$SSH_OVERRIDE" > /dev/null
# SSH overrides from vminit
PermitRootLogin no
PasswordAuthentication no
EOF

echo "Restarting SSH service..."
systemctl restart ssh

echo "Verifying SSH daemon settings:"
sshd -T | grep -E 'permitrootlogin|passwordauthentication'

echo "Ubuntu Setup complete."
