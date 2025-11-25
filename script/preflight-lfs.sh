#!/bin/bash

# Preflight script for LFS build environment
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export LOGROOT=$SRCROOT/logs
export USERNAME=lfs

echo "🚦 Preflight check for LFS build environment..."
date

# === Check mount and swap ===
if ! mountpoint -q "$LFS"; then
  echo "❌ $LFS is not mounted. Please run remount-lfs.sh first."
  exit 1
fi

if ! swapon --show | grep -q "$LFS/swapfile"; then
  echo "⚠️ Swapfile not active. Consider running: sudo swapon $LFS/swapfile"
fi

# === Fix ownership ===
echo "🔧 Ensuring sources and logs directories exist and fixing ownership..."
# Create dirs if missing, then set ownership to $USERNAME
sudo mkdir -pv "$SRCROOT" "$LOGROOT"
sudo chown -R "$USERNAME:$USERNAME" "$SRCROOT" || {
  echo "❌ Failed to chown $SRCROOT"; exit 1; }
sudo chown -R "$USERNAME:$USERNAME" "$LOGROOT" || {
  echo "❌ Failed to chown $LOGROOT"; exit 1; }

# === Check write access as the lfs user ===
if sudo -u "$USERNAME" bash -c "touch \"$SRCROOT/.write-test\" && rm \"$SRCROOT/.write-test\""; then
  echo "✅ $USERNAME can write to $SRCROOT"
else
  echo "❌ $USERNAME cannot write to $SRCROOT. Check permissions."
  exit 1
fi

echo "✅ Preflight complete. Environment is ready for build."