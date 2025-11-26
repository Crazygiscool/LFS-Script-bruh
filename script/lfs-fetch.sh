#!/bin/bash

# LFS Package Fetcher with Retry, Resume, and Integrity Check
# Author: Crazygiscool

set -euo pipefail

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export WGET_LIST=$SRCROOT/wget-list
export MD5_FILE=$SRCROOT/md5sums
export LOG=$SRCROOT/fetch.log
export TMPLIST=$SRCROOT/fetch-temp.list

# Option: --force-continue to proceed even if some files are missing (not recommended)
FORCE_CONTINUE=false
if [ "${1:-}" = "--force-continue" ] || [ "${1:-}" = "--force" ]; then
  FORCE_CONTINUE=true
fi

# === LFS 12.4 official URLs ===
BASE_URL="https://www.linuxfromscratch.org/lfs/downloads/12.4-systemd"
WGET_URL="$BASE_URL/wget-list"
MD5_URL="$BASE_URL/md5sums"

echo "🌐 Starting LFS package fetch..." | tee -a "$LOG"
date | tee -a "$LOG"

mkdir -pv "$SRCROOT"

# === Always refresh wget-list and md5sums ===
echo "⬇️ Fetching wget-list and md5sums..." | tee -a "$LOG"
if ! wget -O "$WGET_LIST" "$WGET_URL" 2>&1 | tee -a "$LOG"; then
  echo "⚠️ Warning: failed to download wget-list from $WGET_URL" | tee -a "$LOG"
fi
if ! wget -O "$MD5_FILE" "$MD5_URL" 2>&1 | tee -a "$LOG"; then
  echo "⚠️ Warning: failed to download md5sums from $MD5_URL" | tee -a "$LOG"
fi

# === Identify missing files ===
echo "🔍 Checking for missing packages..." | tee -a "$LOG"
> "$TMPLIST"

while read -r url; do
  [ -z "$url" ] && continue
  file=$(basename "$url")
  if [ ! -f "$SRCROOT/$file" ]; then
    echo "$url" >> "$TMPLIST"
    echo "🕳️ Missing: $file" | tee -a "$LOG"
  fi
done < "$WGET_LIST"

# === Attempt automatic download of missing files ===
if [ -s "$TMPLIST" ]; then
  echo "📦 Attempting to download missing packages automatically..." | tee -a "$LOG"
  wget --input-file="$TMPLIST" \
       --continue \
       --directory-prefix="$SRCROOT" \
       --tries=3 \
       --timeout=30 \
       2>&1 | tee -a "$LOG" || true

  # Recompute remaining missing files
  REMAINING=$SRCROOT/fetch-remaining.list
  > "$REMAINING"
  while read -r url; do
    [ -z "$url" ] && continue
    file=$(basename "$url")
    if [ ! -f "$SRCROOT/$file" ]; then
      echo "$file" >> "$REMAINING"
    fi
  done < "$TMPLIST"

  if [ -s "$REMAINING" ]; then
    echo "\n⚠️ Some files could not be downloaded automatically." | tee -a "$LOG"
    echo "A list of missing files has been written to: $REMAINING" | tee -a "$LOG"
    echo "You must download these files manually into $SRCROOT before proceeding:" | tee -a "$LOG"
    nl -ba "$REMAINING" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "Manual download instructions:" | tee -a "$LOG"
    echo "  1) For each filename in $REMAINING, fetch the file from the official mirror or alternate mirror." | tee -a "$LOG"
    echo "  2) Place the files in $SRCROOT" | tee -a "$LOG"
    echo "  3) Re-run this script to continue." | tee -a "$LOG"

    if $FORCE_CONTINUE; then
      echo "--force-continue used: continuing despite missing files (not recommended)." | tee -a "$LOG"
    else
      echo "Exiting now so you can download missing files manually." | tee -a "$LOG"
      exit 2
    fi
  else
    echo "✅ Automatic download succeeded for all missing files." | tee -a "$LOG"
  fi
else
  echo "✅ All packages already present." | tee -a "$LOG"
fi

# === Timestamp check for updates ===
echo "🔄 Checking for upstream updates..." | tee -a "$LOG"
wget --input-file="$WGET_LIST" \
     --timestamping \
     --directory-prefix="$SRCROOT" \
     --tries=2 \
     --timeout=20 \
     2>&1 | tee -a "$LOG" || true

# === Verify integrity ===
if [ -f "$MD5_FILE" ]; then
  echo "🔐 Verifying checksums..." | tee -a "$LOG"
  cd "$SRCROOT"
  md5sum -c "$MD5_FILE" 2>&1 | tee -a "$LOG"
else
  echo "⚠️ No md5sums file found. Skipping integrity check." | tee -a "$LOG"
fi

echo "🎉 Fetch complete. Log saved to $LOG"
