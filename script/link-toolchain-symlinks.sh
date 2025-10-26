#!/bin/bash

# Create generic symlinks for toolchain binaries in $LFS/tools/bin
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export TOOLBIN=$LFS/tools/bin
export TARGET=$(uname -m)-lfs-linux-gnu

echo "🔗 Linking generic toolchain binaries..."
cd "$TOOLBIN"

# === List of toolchain commands to symlink ===
tools=(ar as ld nm objcopy objdump ranlib readelf size strings strip)

for tool in "${tools[@]}"; do
  src="$TARGET-$tool"
  dest="$tool"

  if [ -f "$src" ]; then
    ln -svf "$src" "$dest"
    echo "✅ Linked $dest → $src"
  else
    echo "⚠️ Skipped $tool (source $src not found)"
  fi
done

echo "🎉 Symlinks created in $TOOLBIN"
