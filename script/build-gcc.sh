#!/bin/bash

# Build and install GCC cross-compiler into $LFS/tools
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export LOGROOT=$SRCROOT/logs
export MANIFEST=$SRCROOT/build-manifest.txt
export PKG=gcc
export LOGDIR=$LOGROOT/$PKG
export TARGET=$(uname -m)-lfs-linux-gnu

mkdir -pv "$LOGDIR"
echo "[$(date)] $PKG | START" >> "$MANIFEST"

# Detect and extract latest gcc-*.tar.* archive
cd "$SRCROOT"
archive=$(ls -1 gcc-*.tar.* | sort -V | tail -n1)
if [ -z "$archive" ]; then
  echo "❌ No GCC archive found in $SRCROOT"
  exit 1
fi

srcdir=$(basename "$archive" | sed -E 's/\.tar\..*//')

# Extract if build dir doesn't exist
if [ ! -d "$SRCROOT/$srcdir/build" ]; then
  echo "📦 Extracting $archive..."
  rm -rf "$SRCROOT/$srcdir"
  tar -xf "$archive"

  # Nest prerequisites
  cd "$SRCROOT/$srcdir"
  for dep in gmp mpfr mpc; do
    tarball=$(ls -1 ../$dep-*.tar.* | sort -V | tail -n1)
    [ -n "$tarball" ] && tar -xf "$tarball" && mv -v ${dep}-* $dep
  done

  mkdir -v build
fi

cd "$SRCROOT/$srcdir/build"

# Configure if Makefile missing
if [ ! -f Makefile ]; then
  echo "⚙️ Configuring GCC..."
  ../configure --target=$TARGET \
    --prefix=$LFS/tools \
    --with-glibc-version=2.39 \
    --with-newlib --without-headers \
    --enable-default-pie --enable-default-ssp \
    --disable-nls --disable-shared --disable-multilib \
    --disable-decimal-float --disable-threads --disable-libatomic \
    --disable-libgomp --disable-libquadmath --disable-libssp \
    --disable-libvtv --disable-libstdcxx \
    --enable-languages=c \
    --with-native-system-header-dir=/usr/include \
    2>&1 | tee "$LOGDIR/configure.log"
fi

# Build if binary missing
if [ ! -f gcc/xgcc ]; then
  echo "🔨 Building GCC..."
  make -j$(nproc) 2>&1 | tee "$LOGDIR/make.log"
fi

# Always reinstall
echo "📥 Installing GCC to $LFS/tools..."
make install 2>&1 | tee "$LOGDIR/install.log"

echo "[$(date)] $PKG | DONE (installed to $LFS/tools)" >> "$MANIFEST"
echo "✅ GCC installed to $LFS/tools"

# Optional: trigger verification
if [ -x "$SRCROOT/verify-toolchain.sh" ]; then
  echo "🔍 Running post-install toolchain verification..."
  bash "$SRCROOT/verify-toolchain.sh"
fi
