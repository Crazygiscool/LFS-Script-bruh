#!/bin/bash

# Rebuild ncurses for temporary toolchain to restore libtinfo.so.6
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export LOGROOT=$SRCROOT/sources/logs/ncurses-temp
export MANIFEST=$SRCROOT/sources/build-manifest.txt
mkdir -pv "$LOGROOT"

cd "$SRCROOT"
archive=$(ls -1 ncurses-*.tar.* | sort -V | tail -n1)
srcdir=$(basename "$archive" | sed -E 's/\.tar\..*//')

rm -rf "$srcdir"
tar -xf "$archive"
cd "$srcdir"

# === Build host-native tic ===
mkdir -v host-build && cd host-build
../configure --prefix=/tools \
  --with-shared --without-debug \
  --without-normal \
  --build=$(../config.guess) \
  --host=$(../config.guess) \
  --with-build-cc=$(which gcc) \
  2>&1 | tee "$LOGROOT/host-configure.log"
make -j$(nproc) -C progs tic 2>&1 | tee "$LOGROOT/host-tic.log"
TIC_PATH=$(realpath progs/tic)

# === Build target ncurses ===
cd "$SRCROOT/$srcdir"
mkdir -v build && cd build
../configure --prefix=$LFS/tools \
  --with-shared --without-debug \
  --without-normal \
  --host=$(uname -m)-lfs-linux-gnu \
  --build=$(../config.guess) \
  --with-build-cc=$(which gcc) \
  2>&1 | tee "$LOGROOT/configure.log"

make -j$(nproc) 2>&1 | tee "$LOGROOT/make.log"
make TIC_PATH="$TIC_PATH" install 2>&1 | tee "$LOGROOT/install.log"

echo "[$(date)] ncurses-temp | DONE" >> "$MANIFEST"
echo "✅ libtinfo.so.6 should now be in $LFS/tools/lib"
