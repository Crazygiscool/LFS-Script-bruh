#!/bin/bash

# Cleanly unmount LFS chroot environment and log teardown
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export MANIFEST=$LFS/sources/build-manifest.txt
export LOGDIR=$LFS/sources/logs/chroot-exit
mkdir -pv "$LOGDIR"

echo "🧹 Cleaning up LFS chroot mounts..."
date | tee "$LOGDIR/exit.log"

# Unmount in reverse order
for fs in run sys proc dev/pts dev; do
  if mountpoint -q $LFS/$fs; then
    echo "🔻 Unmounting $fs..." | tee -a "$LOGDIR/exit.log"
    sudo umount -l $LFS/$fs
  else
    echo "✅ Already unmounted: $fs" | tee -a "$LOGDIR/exit.log"
  fi
done

echo "[$(date)] chroot-exit | DONE" >> "$MANIFEST"
echo "✅ Chroot environment cleaned up"
