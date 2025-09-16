#!/bin/bash
set -e

PKG=man-pages-6.15
LOG=/logs/system/$PKG.log
SRC=/sources/$PKG

# 🎨 Overlay feedback
echo -e "\n🌀 [Build] $PKG"

# 🧪 Pre-check
if [ ! -f "$SRC.tar.xz" ]; then
  echo "❌ Source tarball missing: $SRC.tar.xz"
  exit 1
fi

# 📦 Extract
cd /sources
rm -rf $PKG
tar -xf $PKG.tar.xz
cd $PKG

# 🧹 Remove obsolete man pages (Libxcrypt replaces these)
rm -v man3/crypt*

# 🛠️ Install
make prefix=/usr install

# 🧼 Cleanup
cd /sources
rm -rf $PKG

echo "✅ $PKG installed successfully"
