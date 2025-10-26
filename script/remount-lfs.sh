#!/bin/bash

# Remount LFS disk image and swapfile
# Author: Crazygiscool

set -e

# === CONFIG ===
LFS_IMG=~/LFS/lfs-disk.img
MOUNT_POINT=/mnt/lfs
SWAPFILE=$MOUNT_POINT/swapfile
LOG=~/LFS/remount.log

echo "🔁 Remounting LFS..." | tee -a "$LOG"
date | tee -a "$LOG"

# === Check image exists ===
if [ ! -f "$LFS_IMG" ]; then
  echo "❌ Disk image not found: $LFS_IMG" | tee -a "$LOG"
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
  echo "💾 Enabling swapfile..." | tee -a "$LOG"
  sudo swapon "$SWAPFILE"
  echo "✅ Swapfile enabled" | tee -a "$LOG"
else
  echo "⚠️ Swapfile not found at $SWAPFILE" | tee -a "$LOG"
fi

# === Set environment ===
export LFS="$MOUNT_POINT"
echo "🌱 LFS environment set to $LFS" | tee -a "$LOG"

echo "🎉 Remount complete." | tee -a "$LOG"