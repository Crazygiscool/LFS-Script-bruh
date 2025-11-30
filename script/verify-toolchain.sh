#!/bin/bash

# Verify LFS temporary toolchain presence and functionality
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export TOOLCHAIN_BIN=$LFS/tools/bin
export TARGET=$(uname -m)-lfs-linux-gnu
export GCC=$TOOLCHAIN_BIN/$TARGET-gcc

echo "🔍 Verifying toolchain presence..."

# === Check key binaries ===
REQUIRED_TOOLS=(
  "$TOOLCHAIN_BIN/ar"
  "$TOOLCHAIN_BIN/as"
  "$TOOLCHAIN_BIN/ld"
  "$TOOLCHAIN_BIN/nm"
  "$TOOLCHAIN_BIN/strip"
  "$GCC"
)

for tool in "${REQUIRED_TOOLS[@]}"; do
  if [ ! -x "$tool" ]; then
    echo "❌ Missing or non-executable: $tool"
    exit 1
  fi
done

echo "✅ All required binaries found."

# === Test cross-compilation ===
echo 'int main(void) { return 0; }' > dummy.c
$GCC dummy.c -o dummy.out

if readelf -l dummy.out | grep -q ': /tools'; then
  echo "🧪 Toolchain test passed: linked to /tools"
  rm -f dummy.c dummy.out
else
  echo "❌ Toolchain test failed: not linked to /tools"
  rm -f dummy.c dummy.out
  exit 1
fi

echo "🎉 Toolchain is present and functional."