#!/usr/bin/env bash
# Dedicated binutils build script
# Builds and installs binutils into $LFS/tools

set -euo pipefail

export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu

SRCROOT="$LFS/sources"
BINUTILS_VERSION=2.45

cd "$SRCROOT"
tar -xf binutils-$BINUTILS_VERSION.tar.xz
cd binutils-$BINUTILS_VERSION
mkdir -v build
cd build

../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT \
             --disable-nls \
             --disable-werror

make
make install

echo "✅ Binutils $BINUTILS_VERSION built and installed to $LFS/tools"
