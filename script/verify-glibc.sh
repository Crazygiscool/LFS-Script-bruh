#!/bin/bash

# Verify glibc installation and linker readiness
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export TARGET=$(uname -m)-lfs-linux-gnu
export GCC=$LFS/tools/bin/$TARGET-gcc
export LOGDIR=$LFS/sources/logs/glibc-verify
mkdir -pv "$LOGDIR"

echo "🔍 Checking glibc startup objects..."
for obj in Scrt1.o crti.o crtn.o; do
  path=$(find $LFS -name "$obj" | head -n1)
  if [ -z "$path" ]; then
    echo "❌ Missing: $obj"
  else
    echo "✅ Found: $obj → $path"
  fi
done

echo "🔍 Checking libc.so..."
libc=$(find $LFS -name "libc.so" | head -n1)
if [ -z "$libc" ]; then
  echo "❌ Missing: libc.so"
else
  echo "✅ Found: libc.so → $libc"
fi

echo "🧪 Compiling test program..."
cat > dummy.c <<EOF
int main(void) { return 0; }
EOF

$GCC dummy.c -o dummy.out 2>&1 | tee "$LOGDIR/link.log"

if [ -f dummy.out ]; then
  echo "✅ Link test passed: dummy.out created"
  rm dummy.c dummy.out
else
  echo "❌ Link test failed — see $LOGDIR/link.log"
fi
