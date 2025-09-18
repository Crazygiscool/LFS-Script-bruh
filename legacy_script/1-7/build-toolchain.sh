#!/bin/bash
set +e  # Continue on errors

# 🧠 Configurable paths
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=$LFS/tools/bin:$PATH
export MAKEFLAGS="-j$(nproc)"
SOURCE_DIR="$LFS/sources"
CHECKSUM_FILE="$SOURCE_DIR/sha256sums.txt"
WGET_LIST_URL="https://www.linuxfromscratch.org/lfs/downloads/development/wget-list"
CHECKSUMS_URL="https://www.linuxfromscratch.org/lfs/downloads/development/sha256sums"

# 🧩 Stage toggles
BUILD_BINUTILS=true
BUILD_GCC=true
BUILD_HEADERS=true
BUILD_GLIBC=true
BUILD_TEMP_TOOLS=true

# 🎨 Overlay feedback
overlay() {
  echo -e "\n🌀 [Overlay] $1"
}

# 🛡️ Preflight check for permissions
preflight_check() {
  if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ $SOURCE_DIR does not exist."
    echo "🔐 Run the following as root before proceeding:"
    echo "  sudo mkdir -pv $SOURCE_DIR"
    echo "  sudo chmod -v a+wt $SOURCE_DIR"
    echo "  sudo chown -v lfs:lfs $SOURCE_DIR"
    exit 1
  fi

  if [ ! -w "$SOURCE_DIR" ]; then
    echo "🔒 $SOURCE_DIR is not writable. You may need to run:"
    echo "  sudo chown -v lfs:lfs $SOURCE_DIR"
    exit 1
  fi
}

# 🌐 Download tarballs and checksums
download_sources() {
  overlay "📥 Downloading LFS sources and checksums"
  cd "$SOURCE_DIR"
  wget -nc "$WGET_LIST_URL" -O wget-list
  wget -nc "$CHECKSUMS_URL" -O sha256sums.txt
  wget --continue --input-file=wget-list
}

# 🔍 Verify checksums
verify_checksums() {
  overlay "🔍 Verifying SHA256 checksums"
  cd "$SOURCE_DIR"
  sha256sum -c sha256sums.txt 2>&1 | grep -E 'FAILED|OK'
}

# 🧼 Safe unpack function
safe_unpack() {
  local pattern="$1"
  local name="$2"
  cd "$SOURCE_DIR" || { echo "❌ Missing sources directory"; return 1; }
  local tarball=$(ls $pattern 2>/dev/null | head -n1)
  if [ -z "$tarball" ]; then
    echo "⚠️ Missing $name tarball, skipping..."
    return 1
  fi
  tar -xf "$tarball"
  cd "${tarball%.tar.*}" || { echo "⚠️ Failed to enter $name source dir"; return 1; }
  return 0
}

# 📦 Binutils - Pass 1
build_binutils() {
  overlay "Building Binutils (Pass 1)"
  safe_unpack "binutils-*.tar.xz" "Binutils" || return
  mkdir -v build && cd build
  ../configure --prefix=$LFS/tools \
    --with-sysroot=$LFS \
    --target=$LFS_TGT \
    --disable-nls \
    --disable-werror
  make && make install
  cd ../.. && rm -rf binutils-*
}

# 📦 GCC - Pass 1
build_gcc() {
  overlay "Building GCC (Pass 1)"
  safe_unpack "gcc-*.tar.xz" "GCC" || return
  mkdir -v build && cd build
  ../configure --target=$LFS_TGT \
    --prefix=$LFS/tools \
    --disable-nls \
    --disable-libssp \
    --disable-multilib \
    --disable-bootstrap \
    --disable-shared \
    --enable-languages=c,c++
  make && make install
  cd ../.. && rm -rf gcc-*
}

# 📦 Linux Headers
build_headers() {
  overlay "Installing Linux API Headers"
  safe_unpack "linux-*.tar.xz" "Linux Headers" || return
  make mrproper
  make headers
  find usr/include -type f ! -name '*.h' -delete
  cp -rv usr/include $LFS/usr
  cd .. && rm -rf linux-*
}

# 📦 Glibc
build_glibc() {
  overlay "Building Glibc"
  safe_unpack "glibc-*.tar.xz" "Glibc" || return
  mkdir -v build && cd build
  ../configure --prefix=/usr \
    --host=$LFS_TGT \
    --build=$(uname -m)-lfs-linux-gnu \
    --enable-kernel=5.4 \
    --with-headers=$LFS/usr/include \
    libc_cv_slibdir=/lib
  make && make DESTDIR=$LFS install
  cd ../.. && rm -rf glibc-*
}

# 📦 Temporary Tools (Coreutils, Bash, etc.)
build_temp_tools() {
  overlay "Building Temporary Tools"
  safe_unpack "coreutils-*.tar.xz" "Coreutils" || return
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(uname -m)
  make && make DESTDIR=$LFS install
  cd .. && rm -rf coreutils-*
  # Repeat for other packages as needed
}

# 🚀 Execution
preflight_check
download_sources
verify_checksums
cd "$SOURCE_DIR" || { echo "❌ Cannot access $SOURCE_DIR"; exit 1; }

if [ "$BUILD_BINUTILS" = true ]; then build_binutils; fi
if [ "$BUILD_GCC" = true ]; then build_gcc; fi
if [ "$BUILD_HEADERS" = true ]; then build_headers; fi
if [ "$BUILD_GLIBC" = true ]; then build_glibc; fi
if [ "$BUILD_TEMP_TOOLS" = true ]; then build_temp_tools; fi

overlay "🎉 Toolchain build complete. Ready for chroot."
