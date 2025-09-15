#!/bin/bash
set -e

echo "🔧 Updating & upgrading package lists..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing required development tools and libraries..."
sudo apt install -y \
  bash \
  binutils \
  bison \
  coreutils \
  diffutils \
  findutils \
  gawk \
  gcc \
  g++ \
  grep \
  gzip \
  linux-source \
  m4 \
  make \
  patch \
  perl \
  python3 \
  sed \
  tar \
  texinfo \
  xz-utils \
  build-essential \
  man-db \
  libncurses-dev \
  libssl-dev \
  libelf-dev \
  libffi-dev \
  zlib1g-dev \
  libcap-dev \
  libtool \
  gettext \
  gdbm-dev \
  libxcrypt-dev \
  libpipeline-dev \
  libxml-parser-perl \
  sqlite3 \
  ninja-build \
  meson \
  kmod \
  grub2 \
  procps \
  sysvinit-utils \
  e2fsprogs \
  sysklogd \
  util-linux \
  vim \
  bc \
  flex \
  tcl \
  expect \
  dejagnu \
  pkgconf \
  gperf \
  expat \
  inetutils \
  less \
  xmlstarlet \
  python3-pip

echo "🧰 Installing Python packaging tools..."
python3 -m pip install --upgrade pip setuptools wheel flit packaging

echo "✅ Host system setup complete for LFS build."
