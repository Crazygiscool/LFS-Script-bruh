#!/bin/bash

# Remount LFS disk image and swapfile
# Author: Crazygiscool

set -e

# === CONFIG ===
LFS_IMG=/root/lfs-root.img
MOUNT_POINT=/mnt/lfs
SWAPFILE=/root/lfs-swap.img
LOG=~/LFS/remount.log

# === Ensure log directory exists ===
mkdir -pv "$(dirname "$LOG")"

echo "🔁 Remounting LFS..." | tee -a "$LOG"
date | tee -a "$LOG"

# === Check image exists ===
if [ ! -f "$LFS_IMG" ]; then
  echo "❌ Disk image not found: $LFS_IMG" | tee -a "$LOG"
  echo "ℹ️ To create the LFS loopback image, run:" | tee -a "$LOG"
  echo "   bash $(dirname "$0")/lfs-loopback-setup.sh" | tee -a "$LOG"
  exit 1
fi

# === Create mount point ===
sudo mkdir -p "$MOUNT_POINT"

# === Mount image ===
echo "📦 Mounting disk image..." | tee -a "$LOG"
sudo mount -o loop "$LFS_IMG" "$MOUNT_POINT"
echo "✅ Mounted at $MOUNT_POINT" | tee -a "$LOG"

# === Enable swap ===
if [ -f "$SWAPFILE" ]; then
  echo "💾 Checking swap status for $SWAPFILE..." | tee -a "$LOG"
  if sudo swapon --show | grep -q "$SWAPFILE"; then
    echo "✅ Swapfile already enabled" | tee -a "$LOG"
  else
    echo "💾 Enabling swapfile..." | tee -a "$LOG"
    sudo swapon "$SWAPFILE"
    if sudo swapon --show | grep -q "$SWAPFILE"; then
      echo "✅ Swapfile enabled successfully" | tee -a "$LOG"
    else
      echo "❌ Failed to enable swapfile $SWAPFILE" | tee -a "$LOG"
    fi
  fi
else
  echo "⚠️ Swapfile not found at $SWAPFILE" | tee -a "$LOG"
fi

# === Set environment ===
export LFS="$MOUNT_POINT"
echo "🌱 LFS environment set to $LFS" | tee -a "$LOG"

echo "🎉 Remount complete." | tee -a "$LOG"