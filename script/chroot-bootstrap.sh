#!/bin/bash

# Run initial native builds inside LFS chroot
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=/sources
export LOGROOT=$SRCROOT/logs/chroot-bootstrap
export MANIFEST=$SRCROOT/build-manifest.txt
mkdir -pv "$LOGROOT"

echo "🚀 Starting chroot bootstrap builds..."
date | tee "$LOGROOT/bootstrap.log"

# === Binutils ===
echo "🔧 Building native Binutils..."
cd $SRCROOT
binutils_src=$(ls -1 binutils-*.tar.* | sort -V | tail -n1)
binutils_dir=$(basename "$binutils_src" | sed -E 's/\.tar\..*//')
[ ! -d "$binutils_dir/build" ] && {
  rm -rf "$binutils_dir"
  tar -xf "$binutils_src"
  mkdir -v "$binutils_dir/build"
}
cd "$binutils_dir/build"
[ ! -f Makefile ] && {
  ../configure --prefix=/usr \
    --build=$(../config.guess) \
    --host=$(uname -m)-lfs-linux-gnu \
    --disable-nls --enable-gold \
    2>&1 | tee "$LOGROOT/binutils-configure.log"
}
make -j$(nproc) 2>&1 | tee "$LOGROOT/binutils-make.log"
make install 2>&1 | tee "$LOGROOT/binutils-install.log"
echo "[$(date)] binutils | DONE" >> "$MANIFEST"

# === GCC ===
echo "🔧 Building native GCC..."
cd $SRCROOT
gcc_src=$(ls -1 gcc-*.tar.* | sort -V | tail -n1)
gcc_dir=$(basename "$gcc_src" | sed -E 's/\.tar\..*//')
[ ! -d "$gcc_dir/build" ] && {
  rm -rf "$gcc_dir"
  tar -xf "$gcc_src"
  cd "$gcc_dir"
  for dep in gmp mpfr mpc; do
    tarball=$(ls -1 ../$dep-*.tar.* | sort -V | tail -n1)
    [ -n "$tarball" ] && tar -xf "$tarball" && mv -v ${dep}-* $dep
  done
  mkdir -v build
}
cd "$SRCROOT/$gcc_dir/build"
[ ! -f Makefile ] && {
  ../configure --prefix=/usr \
    --build=$(../config.guess) \
    --host=$(uname -m)-lfs-linux-gnu \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-bootstrap \
    --disable-libstdcxx-pch \
    2>&1 | tee "$LOGROOT/gcc-configure.log"
}
make -j$(nproc) 2>&1 | tee "$LOGROOT/gcc-make.log"
make install 2>&1 | tee "$LOGROOT/gcc-install.log"
echo "[$(date)] gcc | DONE" >> "$MANIFEST"

# === Glibc ===
echo "🔧 Building native Glibc..."
cd $SRCROOT
glibc_src=$(ls -1 glibc-*.tar.* | sort -V | tail -n1)
glibc_dir=$(basename "$glibc_src" | sed -E 's/\.tar\..*//')
[ ! -d "$glibc_dir/build" ] && {
  rm -rf "$glibc_dir"
  tar -xf "$glibc_src"
  mkdir -v "$glibc_dir/build"
}
cd "$glibc_dir/build"
[ ! -f Makefile ] && {
  ../configure --prefix=/usr \
    --build=$(../scripts/config.guess) \
    --host=$(uname -m)-lfs-linux-gnu \
    --enable-kernel=4.14 \
    --libdir=/usr/lib \
    --with-headers=/usr/include \
    2>&1 | tee "$LOGROOT/glibc-configure.log"
}
make -j$(nproc) 2>&1 | tee "$LOGROOT/glibc-make.log"
make install 2>&1 | tee "$LOGROOT/glibc-install.log"
echo "[$(date)] glibc | DONE" >> "$MANIFEST"

echo "✅ Chroot bootstrap complete"
