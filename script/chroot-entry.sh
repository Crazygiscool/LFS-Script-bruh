#!/bin/bash

# Enter LFS chroot environment with proper mounts and isolation
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs

echo "🚪 Preparing to enter LFS chroot..."
date

# === Mount virtual filesystems ===
echo "🔧 Mounting /dev, /proc, /sys, /run..."
sudo mkdir -pv $LFS/{dev,proc,sys,run}
sudo mount --bind /dev        $LFS/dev
sudo mount --bind /dev/pts    $LFS/dev/pts
sudo mount -t proc  proc      $LFS/proc
sudo mount -t sys   sys       $LFS/sys
sudo mount -t tmpfs tmpfs     $LFS/run

# === Check toolchain presence ===
if [ ! -x "$LFS/tools/bin/bash" ]; then
  echo "❌ Toolchain incomplete: /tools/bin/bash not found"
  exit 1
fi

# === Launch chroot ===
echo "🚀 Entering chroot shell..."
sudo chroot "$LFS" /tools/bin/env -i \
  HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /tools/bin/bash --login +h