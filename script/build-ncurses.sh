#!/bin/bash

# Build and install ncurses inside LFS chroot
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export LOGROOT=$SRCROOT/logs/ncurses
export MANIFEST=$SRCROOT/build-manifest.txt
mkdir -pv "$LOGROOT"

echo "🚀 Starting ncurses build..."
date | tee "$LOGROOT/bootstrap.log"

# === Extract source ===
cd "$SRCROOT"
archive=$(ls -1 ncurses-*.tar.* | sort -V | tail -n1)
srcdir=$(basename "$archive" | sed -E 's/\.tar\..*//')

rm -rf "$srcdir"
tar -xf "$archive"
cd "$srcdir"

# === Configure ===
./configure --prefix=/usr \
  --mandir=/usr/share/man \
  --with-shared \
  --without-debug \
  --without-normal \
  --with-cxx-shared \
  --enable-pc-files \
  --with-pkg-config-libdir=/usr/lib/pkgconfig \
  2>&1 | tee "$LOGROOT/configure.log"

# === Build ===
make -j$(nproc) 2>&1 | tee "$LOGROOT/make.log"

# === Install ===
make install 2>&1 | tee "$LOGROOT/install.log"

# === Symlinks (optional) ===
ln -sv libncursesw.so /usr/lib/libncurses.so
ln -sv libncursesw.so /usr/lib/libcurses.so

# === Manifest entry ===
echo "[$(date)] ncurses | DONE" >> "$MANIFEST"
echo "✅ Ncurses installed — libtinfo.so.6 should now be available"
