#!/bin/bash

# Enter LFS chroot environment with proper mounts and isolation
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export MANIFEST=$LFS/sources/build-manifest.txt
export LOGDIR=$LFS/sources/logs/chroot-entry
mkdir -pv "$LOGDIR"

echo "🚪 Preparing to enter LFS chroot..."
date | tee "$LOGDIR/entry.log"

# === Mount virtual filesystems ===
echo "🔧 Mounting /dev, /proc, /sys, /run..."
for fs in dev dev/pts proc sys run; do
  if ! mountpoint -q $LFS/$fs; then
    sudo mkdir -pv $LFS/$fs
    case $fs in
      dev|dev/pts) sudo mount --bind /$fs $LFS/$fs ;;
      proc)        sudo mount -t proc  proc  $LFS/$fs ;;
      sys)         sudo mount -t sysfs sys   $LFS/$fs ;;
      run)         sudo mount -t tmpfs tmpfs $LFS/$fs ;;
    esac
    echo "✅ Mounted $fs" | tee -a "$LOGDIR/entry.log"
  else
    echo "🔁 Already mounted: $fs" | tee -a "$LOGDIR/entry.log"
  fi
done

# === Check toolchain presence ===
if [ ! -x "$LFS/tools/bin/bash" ]; then
  echo "❌ Toolchain incomplete: /tools/bin/bash not found"
  exit 1
fi

# === Create minimal passwd/group if missing ===
if [ ! -f "$LFS/etc/passwd" ]; then
  echo "👤 Creating /etc/passwd and /etc/group..."
  cat > $LFS/etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
lfs:x:1000:1000:LFS User:/home/lfs:/bin/bash
EOF

  cat > $LFS/etc/group << "EOF"
root:x:0:
lfs:x:1000:
EOF
fi

# === Detect env and bash paths ===
ENV_PATH=""
for path in /usr/bin/env /tools/bin/env; do
  if [ -x "$LFS$path" ]; then ENV_PATH="$path"; break; fi
done

BASH_PATH=""
for path in /bin/bash /tools/bin/bash; do
  if [ -x "$LFS$path" ]; then BASH_PATH="$path"; break; fi
done

# === Launch chroot ===
echo "🚀 Entering chroot shell..."
if [ -n "$ENV_PATH" ]; then
  sudo chroot "$LFS" "$ENV_PATH" -i \
    HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    "$BASH_PATH" --login +h
elif [ -x "$LFS/tools/bin/bash" ]; then
  echo "⚠️ 'env' not found — falling back to direct bash launch"
  sudo chroot "$LFS" /tools/bin/bash --login
else
  echo "❌ No usable bash found in /bin or /tools/bin"
  exit 1
fi

echo "[$(date)] chroot-entry | DONE" >> "$MANIFEST"
