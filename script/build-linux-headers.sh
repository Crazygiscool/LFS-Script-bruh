#!/bin/bash

# Build and install Linux API headers into $LFS/usr/include
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export LOGROOT=$SRCROOT/logs
export MANIFEST=$SRCROOT/build-manifest.txt
export PKG=linux-headers
export LOGDIR=$LOGROOT/$PKG

mkdir -pv "$LOGDIR"
echo "[$(date)] $PKG | START" >> "$MANIFEST"

# Detect and extract latest linux-*.tar.* archive
cd "$SRCROOT"
archive=$(ls -1 linux-*.tar.* | sort -V | tail -n1)
if [ -z "$archive" ]; then
  echo "❌ No Linux source archive found in $SRCROOT"
  exit 1
fi

tar -xf "$archive"
srcdir=$(basename "$archive" | sed -E 's/\.tar\..*//')
cd "$srcdir"

# Clean and prepare
make mrproper 2>&1 | tee "$LOGDIR/mrproper.log"

# Build headers
make headers 2>&1 | tee "$LOGDIR/headers.log"

# Remove hidden files and install headers
find usr/include -name '.*' -delete
cp -rv usr/include "$LFS/usr" 2>&1 | tee "$LOGDIR/install.log"

echo "[$(date)] $PKG | DONE (headers installed from $srcdir)" >> "$MANIFEST"
echo "✅ Linux API headers installed to $LFS/usr/include"
