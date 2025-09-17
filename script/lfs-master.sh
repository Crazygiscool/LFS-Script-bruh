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
bash ./1-7/version-check.sh | tee "$LOG_DIR/version-check.log"

# 📦 Step 1: Package Setup
overlay "Step 1: Downloading and verifying packages"
bash ./1-7/pkg-setup.sh | tee "$LOG_DIR/pkg-setup.log"

# 🛠️ Step 2: Build Toolchain
overlay "Step 2: Building cross-toolchain and temporary tools"
bash ./1-7/build-toolchain.sh | tee "$LOG_DIR/toolchain.log"

# 🔁 Step 3: Resume LFS Build (mounts, user, chroot)
overlay "Step 3: Resuming LFS build stages"
bash ./1-7/resume-lfs.sh | tee "$LOG_DIR/resume.log"

# 🔌 Step 4: Detach LFS (optional teardown)
overlay "Step 4: Detaching LFS environment"
bash ./1-7/detach-lfs.sh | tee "$LOG_DIR/detach.log"

# 🧱 Step 5: Build System Packages (Chapter 8)
overlay "Step 5: Building system packages"
bash ./8-D/build-system.sh | tee "$LOG_DIR/system-build.log"

overlay "🎉 All stages complete. LFS system is built and ready for configuration."
