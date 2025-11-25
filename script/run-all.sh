#!/usr/bin/env bash
# Wrapper to orchestrate the full LFS workflow in this repo
# Creates a safe, idempotent run sequence with dry-run and minimal prompts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Defaults
DRY_RUN=false
ASSUME_YES=false
SKIP_FETCH=false
NO_LOOPBACK=false
USE_AUTO_BUILD=true

LOGFILE="$REPO_ROOT/script/run-all.log"

usage(){
  cat <<EOF
Usage: bash script/run-all.sh [options]

Options:
  --dry-run        Show commands without executing them
  --yes            Assume yes for prompts and run non-interactively
  --skip-fetch     Skip fetching sources (assume sources already present)
  --no-loopback    Do not attempt to mount or setup loopback LFS image
  --no-auto-build  Do not run auto-build; you will run build-* manually
  -h, --help       Show this help

This script runs: version-check -> (mount/setup) -> preflight -> fetch -> auto-build
It logs actions to $LOGFILE
EOF
}

while [[ ${1:-} != "" ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --yes) ASSUME_YES=true; shift ;;
    --skip-fetch) SKIP_FETCH=true; shift ;;
    --no-loopback) NO_LOOPBACK=true; shift ;;
    --no-auto-build) USE_AUTO_BUILD=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

run_cmd(){
  if $DRY_RUN; then
    echo "DRY-RUN: $*"
  else
    echo "+ $*" | tee -a "$LOGFILE"
    eval "$@"
  fi
}

info(){ echo "[INFO] $*" | tee -a "$LOGFILE"; }
warn(){ echo "[WARN] $*" | tee -a "$LOGFILE"; }
err(){ echo "[ERROR] $*" | tee -a "$LOGFILE"; }

mkdir -pv "$(dirname "$LOGFILE")"
echo "Run started: $(date)" > "$LOGFILE"

# Step 1: Version checks
info "Step 1: Running version checks"
run_cmd bash "$SCRIPT_DIR/version-check.sh"

# Step 2: Ensure LFS mount / loopback
export LFS=/mnt/lfs
if ! $NO_LOOPBACK; then
  if mountpoint -q "$LFS"; then
    info "$LFS already mounted"
  else
    if $ASSUME_YES; then
      info "Attempting to remount LFS image (non-interactive)"
      run_cmd bash "$SCRIPT_DIR/remount-lfs.sh"
      if ! mountpoint -q "$LFS"; then
        warn "remount-lfs.sh did not mount LFS. Attempting loopback setup (may require interaction)"
        run_cmd bash "$SCRIPT_DIR/lfs-loopback-setup.sh"
      fi
    else
      echo "LFS mount not found at $LFS."
      read -rp "Run remount-lfs.sh now? [y/N] " resp
      if [[ "$resp" =~ ^[Yy]$ ]]; then
        run_cmd bash "$SCRIPT_DIR/remount-lfs.sh"
      else
        echo "Skipping remount. You can run remount-lfs.sh or lfs-loopback-setup.sh later."
      fi
    fi
  fi
else
  info "Skipping loopback/mount step by request (--no-loopback)"
fi

# Step 3: Preflight
info "Step 3: Preflight checks"
run_cmd bash "$SCRIPT_DIR/preflight-lfs.sh"

# Step 4: Fetch sources
if $SKIP_FETCH; then
  info "Skipping fetch step (--skip-fetch)"
else
  info "Step 4: Fetching LFS sources"
  run_cmd bash "$SCRIPT_DIR/lfs-fetch.sh"
fi

# Step 5: Build
if $USE_AUTO_BUILD; then
  info "Step 5: Running auto-build (build all packages found in sources)"
  run_cmd bash "$SCRIPT_DIR/auto-build.sh"
else
  info "Auto-build disabled. You can run specific build scripts manually: build-linux-headers.sh, build-gcc.sh, build-glibc.sh, etc."
fi

# Step 6: Post-verification
info "Step 6: Post-build verification"
if [ -x "$SCRIPT_DIR/verify-toolchain.sh" ]; then
  run_cmd bash "$SCRIPT_DIR/verify-toolchain.sh"
fi
if [ -x "$SCRIPT_DIR/verify-glibc.sh" ]; then
  run_cmd bash "$SCRIPT_DIR/verify-glibc.sh"
fi

echo "Run finished: $(date)" >> "$LOGFILE"
info "All steps completed. See $LOGFILE for details."

exit 0
