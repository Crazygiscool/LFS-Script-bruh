#!/bin/bash
set -e

# 🧠 Configurable paths
export LFS=/mnt/lfs
export SOURCE_DIR="$LFS/sources"
export LOG_DIR="$LFS/logs"
mkdir -pv "$LOG_DIR"

# 🎨 Overlay feedback
overlay() { echo -e "\n🌀 [Overlay] $1"; }

# 🧪 Step 0: Host Compatibility Check
overlay "Step 0: Checking host system compatibility"
bash ./version-check.sh | tee "$LOG_DIR/version-check.log"

# 📦 Step 1: Package Setup
overlay "Step 1: Downloading and verifying packages"
bash ./pkg-setup.sh | tee "$LOG_DIR/pkg-setup.log"

# 🛠️ Step 2: Build Toolchain
overlay "Step 2: Building cross-toolchain and temporary tools"
bash ./build-toolchain.sh | tee "$LOG_DIR/toolchain.log"

# 🔁 Step 3: Resume LFS Build
overlay "Step 3: Resuming LFS build stages"
bash ./resume-lfs.sh | tee "$LOG_DIR/resume.log"

overlay "🎉 All stages complete. Ready for chroot and final build."
