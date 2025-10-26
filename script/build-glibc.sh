#!/bin/bash

# Build and install glibc into $LFS using Linux headers
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export LOGROOT=$SRCROOT/logs
export MANIFEST=$SRCROOT/build-manifest.txt
export PKG=glibc
export LOGDIR=$LOGROOT/$PKG
export TARGET=$(uname -m)-lfs-linux-gnu

mkdir -pv "$LOGDIR"
echo "[$(date)] $PKG | START" >> "$MANIFEST"

# Detect and extract latest glibc-*.tar.* archive
cd "$SRCROOT"
archive=$(ls -1 glibc-*.tar.* | sort -V | tail -n1)
if [ -z "$archive" ]; then
  echo "❌ No glibc archive found in $SRCROOT"
  exit 1
fi

tar -xf "$archive"
srcdir=$(basename "$archive" | sed -E 's/\.tar\..*//')
cd "$srcdir"

mkdir -v build
cd build

# Configure
../configure --prefix=/usr \
  --host=$TARGET \
  --build=$(../scripts/config.guess) \
  --enable-kernel=4.14 \
  --with-headers=$LFS/usr/include \
  2>&1 | tee "$LOGDIR/configure.log"

# Build
make -j$(nproc) 2>&1 | tee "$LOGDIR/make.log"

# Install into $LFS
make DESTDIR=$LFS install 2>&1 | tee "$LOGDIR/install.log"

echo "[$(date)] $PKG | DONE (installed to $LFS/usr)" >> "$MANIFEST"
echo "✅ Glibc installed to $LFS/usr"
