#!/bin/bash
set +e  # Allow script to continue on errors

echo "🔍 Detecting package manager..."

# Detect package manager
if command -v apt-get &>/dev/null; then
  PM="apt-get"
  INSTALL="sudo apt-get install -y"
elif command -v dnf &>/dev/null; then
  PM="dnf"
  INSTALL="sudo dnf install -y"
elif command -v yum &>/dev/null; then
  PM="yum"
  INSTALL="sudo yum install -y"
elif command -v pacman &>/dev/null; then
  PM="pacman"
  INSTALL="sudo pacman -S --noconfirm"
elif command -v zypper &>/dev/null; then
  PM="zypper"
  INSTALL="sudo zypper install -y"
elif command -v apk &>/dev/null; then
  PM="apk"
  INSTALL="sudo apk add"
else
  echo "❌ Unsupported package manager. Please install packages manually."
  exit 1
fi

echo "✅ Using package manager: $PM"

# Core packages required for LFS host system
PACKAGES=(
  bash binutils bison coreutils diffutils findutils gawk gcc g++ grep gzip
  m4 make patch perl python3 sed tar texinfo xz-utils build-essential
  man-db libncurses-dev libssl-dev libelf-dev libffi-dev zlib1g-dev
  libcap-dev libtool gettext gdbm-dev libxcrypt-dev libpipeline-dev
  libxml-parser-perl sqlite3 ninja-build meson kmod grub2 procps
  sysvinit-utils e2fsprogs sysklogd util-linux vim bc flex tcl expect
  dejagnu pkgconf gperf expat inetutils less xmlstarlet
)

echo "📦 Installing packages..."
for pkg in "${PACKAGES[@]}"; do
  echo "➡️ Installing $pkg..."
  $INSTALL "$pkg" || echo "⚠️ Failed to install $pkg, continuing..."
done

# Python packaging tools
echo "🐍 Installing Python packaging tools..."
python3 -m pip install --upgrade pip setuptools wheel flit packaging || echo "⚠️ Python pip install failed"

echo "🎉 Host system setup complete for LFS build."
