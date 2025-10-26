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
echo "🔧 Fixing ownership of sources and logs..."
sudo chown -R $USERNAME:$USERNAME "$SRCROOT"
sudo chown -R $USERNAME:$USERNAME "$LOGROOT"

# === Check write access ===
touch "$SRCROOT/.write-test" && rm "$SRCROOT/.write-test" || {
  echo "❌ Cannot write to $SRCROOT. Check permissions."
  exit 1
}

echo "✅ Preflight complete. Environment is ready for build."