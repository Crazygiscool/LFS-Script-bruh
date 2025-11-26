#!/usr/bin/env bash
# Create lfs user if missing, then switch to it
# If lfs user already exists, just switch to it
# Author: Crazygiscool

set -euo pipefail

USERNAME=lfs
GROUP=lfs
HOME_DIR="/home/${USERNAME}"
SHELL_BIN="/bin/bash"

info(){ echo "[INFO] $*"; }
err(){ echo "[ERROR] $*" >&2; exit 1; }
warn(){ echo "[WARN] $*"; }

info "Checking if user '$USERNAME' exists..."

# Check if user exists
if id -u "$USERNAME" >/dev/null 2>&1; then
  info "User '$USERNAME' already exists (uid: $(id -u $USERNAME))"
else
  info "User '$USERNAME' does not exist. Creating..."
  
  # Create group if missing
  if getent group "$GROUP" >/dev/null; then
    info "Group '$GROUP' already exists"
  else
    info "Creating group '$GROUP'..."
    sudo groupadd "$GROUP"
  fi
  
  # Create user
  info "Creating user '$USERNAME'..."
  sudo useradd -m -d "$HOME_DIR" -s "$SHELL_BIN" -g "$GROUP" "$USERNAME"
  
  # Ensure home exists and is owned by lfs
  sudo mkdir -p "$HOME_DIR"
  sudo chown -R "$USERNAME:$GROUP" "$HOME_DIR"
  
  info "User '$USERNAME' created successfully"
fi

# Ensure lfs can sudo without password (needed for build scripts)
if [ ! -f /etc/sudoers.d/99_lfs ]; then
  info "Adding $USERNAME to sudoers (NOPASSWD)..."
  echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/99_lfs >/dev/null
  sudo chmod 0440 /etc/sudoers.d/99_lfs
else
  info "Sudoers file for $USERNAME already exists"
fi

# Ensure /mnt/lfs/sources and /mnt/lfs/sources/logs are owned by lfs
if [ -d /mnt/lfs/sources ]; then
  info "Fixing ownership of /mnt/lfs/sources..."
  sudo chown -R "$USERNAME:$GROUP" /mnt/lfs/sources
fi

info "Switching to user '$USERNAME'..."
info "To exit this shell, type: exit"

# Switch to lfs user
su - "$USERNAME"

