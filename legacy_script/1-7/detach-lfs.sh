#!/bin/bash
set -e

# 🧠 Configurable paths
export LFS=/mnt/lfs
export LFS_IMG=~/lfs.img
export LFS_LOOPDEV=""

# 🎨 Overlay feedback
overlay() { echo -e "\n🌀 [Overlay] $1"; }

# 🔍 Detect loop device
if [ -f "$LFS_IMG" ]; then
  LFS_LOOPDEV=$(losetup -j "$LFS_IMG" | cut -d: -f1)
  if [ -z "$LFS_LOOPDEV" ]; then
    overlay "⚠️ No active loop device found for $LFS_IMG"
  else
    overlay "🔗 Detected loop device: $LFS_LOOPDEV"
  fi
fi

# 🧹 Unmount virtual filesystems
overlay "Unmounting virtual filesystems from $LFS"
for fs in run sys proc dev/pts dev; do
  mountpoint -q "$LFS/$fs" && sudo umount -v "$LFS/$fs"
done

# 📂 Unmount root LFS
if mountpoint -q "$LFS"; then
  overlay "Unmounting $LFS"
  sudo umount -v "$LFS"
else
  overlay "⚠️ $LFS is not mounted"
fi

# 🔌 Detach loop device
if [ -n "$LFS_LOOPDEV" ]; then
  overlay "Detaching loop device $LFS_LOOPDEV"
  sudo losetup -d "$LFS_LOOPDEV"
fi

overlay "🎉 LFS teardown complete. Environment is clean."
