#!/bin/bash
set +e  # Allow errors to be handled manually

# 🧠 Configurable paths
export LOG_DIR="/logs/system"
mkdir -pv "$LOG_DIR"

# 🎨 TUI feedback
overlay() { echo -e "\n🌀 [Build] $1"; }
success() { echo -e "✅ $1"; }
fail() { echo -e "❌ $1"; }

# 📦 Package list (Chapter 8)
PACKAGES=(
  "man-pages" "iana-etc" "glibc" "zlib" "bzip2" "xz" "lz4" "zstd"
  "file" "readline" "pcre2" "m4" "bc" "flex" "tcl" "expect" "dejagnu"
  "pkgconf" "binutils" "gmp" "mpfr" "mpc" "attr" "acl" "libcap"
  "libxcrypt" "shadow" "gcc" "ncurses" "sed" "psmisc" "gettext"
  "bison" "grep" "bash" "libtool" "gdbm" "gperf" "expat" "inetutils"
  "less" "perl" "xml-parser" "intltool" "autoconf" "automake"
  "openssl" "libelf" "libffi" "sqlite" "python" "flit-core"
  "packaging" "wheel" "setuptools" "ninja" "meson" "kmod"
  "coreutils" "diffutils" "gawk" "findutils" "groff" "grub"
  "gzip" "iproute2" "kbd" "libpipeline" "make" "patch" "tar"
  "texinfo" "vim" "markupsafe" "jinja2" "udev" "man-db"
  "procps-ng" "util-linux" "e2fsprogs" "sysklogd" "sysvinit"
)

# 🛠️ Build loop
for pkg in "${PACKAGES[@]}"; do
  overlay "Building $pkg..."
  if [ -x "./build/$pkg.sh" ]; then
    ./build/$pkg.sh 2>&1 | tee "$LOG_DIR/$pkg.log"
    if [ "${PIPESTATUS[0]}" -eq 0 ]; then
      success "$pkg built successfully"
    else
      fail "$pkg failed. Check $LOG_DIR/$pkg.log"
      read -p "⏸️ Continue anyway? [y/N]: " choice
      [[ "$choice" != "y" ]] && exit 1
    fi
  else
    fail "Missing build script: ./build/$pkg.sh"
    read -p "⏸️ Continue anyway? [y/N]: " choice
    [[ "$choice" != "y" ]] && exit 1
  fi
done

overlay "🎉 All system packages built. Proceed to Chapter 9 configuration."
