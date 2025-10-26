#!/bin/bash

# Fetch latest GMP, MPFR, MPC and nest into GCC source tree
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
cd "$SRCROOT"

# === Detect GCC folder ===
GCCDIR=$(find . -maxdepth 1 -type d -name "gcc-*" | head -n 1)
if [ -z "$GCCDIR" ]; then
  echo "❌ GCC source folder not found in $SRCROOT"
  exit 1
fi
echo "📦 Detected GCC source: $GCCDIR"

# === GMP ===
echo "🌐 Fetching GMP..."
wget -N https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
tar -xf gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 "$GCCDIR/gmp"

# === MPFR ===
echo "🌐 Fetching MPFR..."
wget -N https://www.mpfr.org/mpfr-4.2.2/mpfr-4.2.2.tar.xz
tar -xf mpfr-4.2.2.tar.xz
mv -v mpfr-4.2.2 "$GCCDIR/mpfr"

# === MPC ===
echo "🌐 Fetching MPC..."
wget -N https://www.multiprecision.org/mpc/download/mpc-1.3.1.tar.gz
tar -xf mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 "$GCCDIR/mpc"

echo "✅ All prerequisites nested inside $GCCDIR"
