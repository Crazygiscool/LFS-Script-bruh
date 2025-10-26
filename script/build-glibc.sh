#!/bin/bash

# Build and install glibc into $LFS with libdir override
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

srcdir=$(basename "$archive" | sed -E 's/\.tar\..*//')

# Extract only if build dir doesn't exist
if [ ! -d "$SRCROOT/$srcdir/build" ]; then
  echo "📦 Extracting $archive..."
  rm -rf "$SRCROOT/$srcdir"
  tar -xf "$archive"
  mkdir -v "$SRCROOT/$srcdir/build"
fi

cd "$SRCROOT/$srcdir/build"

# Configure only if Makefile doesn't exist
if [ ! -f Makefile ]; then
  echo "⚙️ Configuring glibc..."
  ../configure --prefix=/usr \
    --host=$TARGET \
    --build=$(../scripts/config.guess) \
    --enable-kernel=4.14 \
    --with-headers=$LFS/usr/include \
    --libdir=/usr/lib \
    2>&1 | tee "$LOGDIR/configure.log"
fi

# Build only if binary not present
if [ ! -f libc.so ]; then
  echo "🔨 Building glibc..."
  make -j$(nproc) 2>&1 | tee "$LOGDIR/make.log"
fi

# Always reinstall
echo "📥 Installing glibc into $LFS..."
make DESTDIR=$LFS install 2>&1 | tee "$LOGDIR/install.log"

echo "[$(date)] $PKG | DONE (installed to $LFS/usr/lib)" >> "$MANIFEST"
echo "✅ Glibc installed to $LFS/usr/lib"

# Optional: trigger verification
if [ -x "$SRCROOT/verify-glibc.sh" ]; then
  echo "🔍 Running post-install verification..."
  bash "$SRCROOT/verify-glibc.sh"
fi
