#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# Update and upgrade packages
apt update

# Install prerequisites
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Add Docker’s official GPG key (new method for apt >= 2.4)
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker's repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with Docker packages
apt update

# Install Docker Engine
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker daemon
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Ensure Docker uses the systemd cgroup driver
mkdir -p /etc/systemd/system/docker.service.d

# Reload and restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

echo "Docker installed successfully!"
