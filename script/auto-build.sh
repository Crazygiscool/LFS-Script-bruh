#!/bin/bash

# Auto-build all tarballs in $LFS/sources with special-case support, live logging, build verification, and error suggestions
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export LOGROOT=$SRCROOT/logs
export MANIFEST=$SRCROOT/build-manifest.txt
export NPROC=$(nproc)
export TARGET=$(uname -m)-lfs-linux-gnu

mkdir -pv "$LOGROOT"
echo "📋 Build Manifest — $(date)" > "$MANIFEST"

# === Special Package Handlers ===

handle_binutils() {
  mkdir -v build && cd build
  ../configure --prefix=$LFS/tools \
    --with-sysroot=$LFS \
    --target=$TARGET \
    --disable-nls --disable-werror
}

handle_gcc() {
  mkdir -v build && cd build
  ../configure --target=$TARGET --prefix=$LFS/tools \
    --with-glibc-version=2.39 --with-newlib --without-headers \
    --enable-default-pie --enable-default-ssp \
    --disable-nls --disable-shared --disable-multilib \
    --disable-decimal-float --disable-threads --disable-libatomic \
    --disable-libgomp --disable-libquadmath --disable-libssp \
    --disable-libvtv --disable-libstdcxx \
    --enable-languages=c
}

handle_linux() {
  make mrproper
  make headers
  find usr/include -name '.*' -delete
  cp -rv usr/include $LFS/usr
}

handle_glibc() {
  mkdir -v build && cd build
  ../configure --prefix=/usr \
    --host=$TARGET --build=$(../scripts/config.guess) \
    --enable-kernel=4.14 --with-headers=$LFS/usr/include
}

handle_libstdcpp() {
  mkdir -v build && cd build
  ../configure --host=$TARGET --prefix=$LFS/tools \
    --disable-multilib --disable-nls --disable-libstdcxx-pch \
    --with-gxx-include-dir=$LFS/tools/$TARGET/include/c++/13.2.0
}

# === Error Suggestions ===
suggest_fix() {
  local stage="$1"
  local pkg="$2"
  echo "💡 Suggestions for $pkg ($stage failure):"
  case "$stage" in
    archive)
      echo "   • Archive may be corrupted or incomplete."
      echo "   • Delete and re-fetch: rm -f $SRCROOT/${pkg}.tar.* && rerun fetch."
      echo "   • Verify checksum against official source."
      ;;
    configure)
      echo "   • Check $LOGROOT/$pkg/configure.log for missing dependencies or wrong flags."
      echo "   • Verify required tools (gcc, make, bash, etc.) are installed and in PATH."
      echo "   • Ensure correct --prefix and --host/--target values for cross-compilation."
      ;;
    make)
      echo "   • Inspect $LOGROOT/$pkg/make.log for compiler errors."
      echo "   • Check disk space and memory availability."
      echo "   • Try rebuilding with fewer jobs: make -j1"
      ;;
    install)
      echo "   • Review $LOGROOT/$pkg/install.log for permission issues."
      echo "   • Ensure $LFS/tools or $LFS/usr is writable by the lfs user."
      echo "   • Check if previous steps installed required headers/libraries."
      ;;
  esac
}

# === Build Loop ===

for archive in "$SRCROOT"/*.tar.*; do
  pkg=$(basename "$archive" | sed -E 's/\.tar\..*//')
  srcdir="$SRCROOT/$pkg"
  builddir="$srcdir/build"
  logdir="$LOGROOT/$pkg"

  echo "🔧 Building $pkg..."
  echo "[$(date)] $pkg | START" >> "$MANIFEST"

  # Skip if already built
  if [ -f "$logdir/install.log" ]; then
    echo "⏩ Skipping $pkg (already built)" | tee -a "$MANIFEST"
    continue
  fi

  rm -rf "$srcdir" "$builddir"
  mkdir -pv "$logdir"

  # === Check archive integrity before extraction ===
  if ! tar -tf "$archive" &>/dev/null; then
    echo "❌ Archive appears corrupted: $archive"
    suggest_fix archive "$pkg"
    echo "[$(date)] $pkg | ERROR (archive)" >> "$MANIFEST"
    continue
  fi

  tar -xf "$archive" -C "$SRCROOT" || {
    echo "❌ Extraction failed for $pkg"
    suggest_fix archive "$pkg"
    echo "[$(date)] $pkg | ERROR (extract)" >> "$MANIFEST"
    continue
  }

  cd "$srcdir"

  env > "$logdir/env.txt"
  date > "$logdir/start.txt"

  # Special cases
  case "$pkg" in
    binutils-*)
      handle_binutils 2>&1 | tee "$logdir/configure.log"
      ;;
    gcc-*)
      handle_gcc 2>&1 | tee "$logdir/configure.log"
      ;;
    linux-*)
      handle_linux 2>&1 | tee "$logdir/headers.log"
      echo "✅ Installed Linux headers"
      echo "[$(date)] $pkg | DONE (headers only)" >> "$MANIFEST"
      continue
      ;;
    glibc-*)
      handle_glibc 2>&1 | tee "$logdir/configure.log"
      ;;
    libstdc++-*)
      handle_libstdcpp 2>&1 | tee "$logdir/configure.log"
      ;;
    *)
      mkdir -v build && cd build
      ../configure --prefix=$LFS/tools 2>&1 | tee "$logdir/configure.log" || {
        echo "⚠️ Configure failed for $pkg — skipping"
        suggest_fix configure "$pkg"
        echo "[$(date)] $pkg | ERROR (configure)" >> "$MANIFEST"
        continue
      }
      ;;
  esac

  make -j"$NPROC" 2>&1 | tee "$logdir/make.log" || {
    echo "⚠️ Make failed for $pkg — skipping"
    suggest_fix make "$pkg"
    echo "[$(date)] $pkg | ERROR (make)" >> "$MANIFEST"
    continue
  }

  make install 2>&1 | tee "$logdir/install.log" || {
    echo "⚠️ Install failed for $pkg — skipping"
    suggest_fix install "$pkg"
    echo "[$(date)] $pkg | ERROR (install)" >> "$MANIFEST"
    continue
  }

  # === Post-build verification ===
  success=false
  if grep -q "Leaving directory" "$logdir/make.log"; then
    success=true
  elif find $LFS/tools -type f -name "${pkg%%-*}*" | grep -q .; then
    success=true
  fi

  date > "$logdir/end.txt"

  if $success; then
    echo "✅ $pkg built successfully."
    echo "[$(date)] $pkg | SUCCESS" >> "$MANIFEST"
  else
    echo "⚠️ $pkg built but verification uncertain."
    echo "[$(date)] $pkg | PARTIAL" >> "$MANIFEST"
  fi
done

echo "🎉 All packages processed with build verification, corruption checks, and error suggestions."
