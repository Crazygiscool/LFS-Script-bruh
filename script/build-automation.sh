#!/usr/bin/env bash
# Master automation script: complete LFS build workflow from scratch
# Handles: user creation, loopback setup, preflight, fetch, build, verification
# Author: Crazygiscool

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Defaults
SKIP_USER_CREATE=false
SKIP_LOOPBACK=false
SKIP_FETCH=false
NO_AUTO_BUILD=false
DRY_RUN=false

LOGFILE="$REPO_ROOT/script/build-automation.log"

usage(){
  cat <<EOF
Usage: sudo bash script/build-automation.sh [options]

Complete automation: creates lfs user, sets up loopback, runs full build.

Options:
  --skip-user      Do not create lfs user (assume it exists)
  --skip-loopback  Do not setup loopback (assume /mnt/lfs is mounted)
  --skip-fetch     Skip fetching sources
  --no-auto-build  Run build scripts manually instead of auto-build
  --dry-run        Show what would be executed (dry-run mode)
  -h, --help       Show this help

Running without options will:
  1. Create lfs user (if missing)
  2. Setup loopback image (if not mounted)
  3. Run preflight checks
  4. Fetch LFS sources
  5. Run auto-build (or show manual build instructions)
  6. Run post-build verification

Logs are saved to: $LOGFILE
EOF
}

while [[ ${1:-} != "" ]]; do
  case "$1" in
    --skip-user) SKIP_USER_CREATE=true; shift ;;
    --skip-loopback) SKIP_LOOPBACK=true; shift ;;
    --skip-fetch) SKIP_FETCH=true; shift ;;
    --no-auto-build) NO_AUTO_BUILD=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Ensure running as root for privileged operations
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script requires root privileges (run with sudo)"
  echo "   sudo bash script/build-automation.sh [options]"
  exit 1
fi

run_cmd(){
  if $DRY_RUN; then
    echo "DRY-RUN: $*"
  else
    echo "+ $*" | tee -a "$LOGFILE"
    eval "$@"
  fi
}

check_script_exists(){
  local script="$1"
  if [ ! -f "$script" ]; then
    err "Script not found: $script"
  fi
}

check_executable(){
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    err "Required command not found: $cmd"
  fi
}

check_file_readable(){
  local file="$1"
  if [ ! -r "$file" ]; then
    err "File not readable: $file"
  fi
}

check_mount_point(){
  local mp="$1"
  if ! mountpoint -q "$mp"; then
    return 1
  fi
  return 0
}

check_directory_writable(){
  local dir="$1"
  if [ ! -w "$dir" ]; then
    return 1
  fi
  return 0
}

info(){ echo "[INFO] $*" | tee -a "$LOGFILE"; }
warn(){ echo "[WARN] $*" | tee -a "$LOGFILE"; }
err(){ echo "[ERROR] $*" | tee -a "$LOGFILE"; exit 1; }

mkdir -pv "$(dirname "$LOGFILE")"
echo "=== Build Automation Started: $(date) ===" > "$LOGFILE"

# ============================================================================
# Step 1: Create lfs user if needed
# ============================================================================
if ! $SKIP_USER_CREATE; then
  info "Step 1: Creating/verifying lfs user"
  
  # Pre-check
  check_script_exists "$SCRIPT_DIR/create-lfs-user.sh"
  
  if id -u lfs >/dev/null 2>&1; then
    info "User 'lfs' already exists (uid: $(id -u lfs))"
  else
    info "Creating lfs user and group..."
    run_cmd bash "$SCRIPT_DIR/create-lfs-user.sh"
  fi
  
  # Ensure sudoers entry exists
  if [ ! -f /etc/sudoers.d/99_lfs ]; then
    info "Adding lfs to sudoers (NOPASSWD)..."
    echo "lfs ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/99_lfs >/dev/null
    chmod 0440 /etc/sudoers.d/99_lfs
  else
    info "Sudoers file for lfs already exists"
  fi
else
  info "Skipping lfs user creation (--skip-user)"
fi

# ============================================================================
# Step 2: Setup loopback LFS filesystem if needed
# ============================================================================
if ! $SKIP_LOOPBACK; then
  export LFS=/mnt/lfs
  
  # Pre-checks
  check_script_exists "$SCRIPT_DIR/remount-lfs.sh"
  check_script_exists "$SCRIPT_DIR/lfs-loopback-setup.sh"
  
  if check_mount_point "$LFS"; then
    info "Step 2: $LFS already mounted ($(df -h "$LFS" | tail -1 | awk '{print $5}') used)"
  else
    info "Step 2: Setting up loopback LFS filesystem"
    
    # Try remount first
    if [ -f ~/lfs-disk.img ]; then
      info "Disk image exists at ~/lfs-disk.img, attempting remount..."
      run_cmd bash "$SCRIPT_DIR/remount-lfs.sh"
    else
      info "No disk image found at ~/lfs-disk.img. Creating new loopback image..."
      run_cmd bash "$SCRIPT_DIR/lfs-loopback-setup.sh"
    fi
    
    # Verify mount
    if ! check_mount_point "$LFS"; then
      err "Failed to mount $LFS — check logs or run setup manually"
    fi
    info "$LFS mounted successfully"
  fi
else
  info "Skipping loopback setup (--skip-loopback)"
  export LFS=/mnt/lfs
fi

# ============================================================================
# Step 3: Run preflight checks
# ============================================================================
info "Step 3: Running preflight checks"

# Pre-checks
check_script_exists "$SCRIPT_DIR/preflight-lfs.sh"
if ! check_mount_point "$LFS"; then
  err "LFS not mounted at $LFS — cannot run preflight"
fi

run_cmd bash "$SCRIPT_DIR/preflight-lfs.sh"

# ============================================================================
# Step 4: Fetch LFS sources
# ============================================================================
if $SKIP_FETCH; then
  info "Step 4: Skipping fetch (--skip-fetch)"
else
  info "Step 4: Fetching LFS sources"
  
  # Pre-checks
  check_script_exists "$SCRIPT_DIR/lfs-fetch.sh"
  check_executable wget
  
  SRCROOT="$LFS/sources"
  if ! check_directory_writable "$SRCROOT"; then
    warn "$SRCROOT not writable — attempting to create and fix permissions"
    run_cmd mkdir -pv "$SRCROOT"
    run_cmd chown -R lfs:lfs "$SRCROOT"
  fi
  
  run_cmd bash "$SCRIPT_DIR/lfs-fetch.sh"
fi

# ============================================================================
# Step 5: Build packages
# ============================================================================
if $NO_AUTO_BUILD; then
  info "Step 5: Auto-build disabled. Available build scripts:"
  info "  - build-linux-headers.sh    (Linux API headers)"
  info "  - build-gcc.sh              (GCC cross-compiler)"
  info "  - build-glibc.sh            (GNU C Library)"
  info "  - build-ncurses-temp.sh     (Ncurses for temporary tools)"
  info "  - build-ncurses.sh          (Ncurses final)"
  info "  Run manually or use: su - lfs && bash build-*.sh"
else
  info "Step 5: Running auto-build (all packages in $LFS/sources)"
  
  # Pre-checks
  check_script_exists "$SCRIPT_DIR/auto-build.sh"
  
  SRCROOT="$LFS/sources"
  if [ -z "$(ls -1 "$SRCROOT"/*.tar.* 2>/dev/null)" ]; then
    err "No source tarballs found in $SRCROOT — run fetch first"
  fi
  
  # Verify lfs user exists
  if ! id -u lfs >/dev/null 2>&1; then
    err "User 'lfs' does not exist — run user creation step first"
  fi
  
  run_cmd bash "$SCRIPT_DIR/auto-build.sh"
fi

# ============================================================================
# Step 6: Post-build verification
# ============================================================================
info "Step 6: Running post-build verification"

# Pre-checks
if [ ! -x "$SCRIPT_DIR/verify-toolchain.sh" ]; then
  warn "verify-toolchain.sh not found or not executable — skipping"
else
  info "Verifying toolchain..."
  run_cmd bash "$SCRIPT_DIR/verify-toolchain.sh"
fi

if [ ! -x "$SCRIPT_DIR/verify-glibc.sh" ]; then
  warn "verify-glibc.sh not found or not executable — skipping"
else
  info "Verifying glibc..."
  run_cmd bash "$SCRIPT_DIR/verify-glibc.sh"
fi

# ============================================================================
# Success summary
# ============================================================================
echo "=== Build Automation Completed: $(date) ===" >> "$LOGFILE"
info ""
info "✅ Automation complete!"
info "Log file: $LOGFILE"
info ""
info "Next steps (as lfs user):"
info "  su - lfs"
info "  cd /mnt/lfs/sources"
info "  # Run build-* scripts or auto-build"
info ""

exit 0
