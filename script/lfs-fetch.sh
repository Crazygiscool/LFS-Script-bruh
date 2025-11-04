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

# === LFS 12.4 official URLs ===
BASE_URL="https://www.linuxfromscratch.org/lfs/downloads/12.4-systemd"
WGET_URL="$BASE_URL/wget-list"
MD5_URL="$BASE_URL/md5sums"

echo "🌐 Starting LFS package fetch..." | tee -a "$LOG"
date | tee -a "$LOG"

mkdir -pv "$SRCROOT"

# === Always refresh wget-list and md5sums ===
echo "⬇️ Fetching wget-list and md5sums..." | tee -a "$LOG"
wget -O "$WGET_LIST" "$WGET_URL" 2>&1 | tee -a "$LOG"
wget -O "$MD5_FILE" "$MD5_URL" 2>&1 | tee -a "$LOG"

# === Identify missing files ===
echo "🔍 Checking for missing packages..." | tee -a "$LOG"
> "$TMPLIST"

while read -r url; do
  file=$(basename "$url")
  if [ ! -f "$SRCROOT/$file" ]; then
    echo "$url" >> "$TMPLIST"
    echo "🕳️ Missing: $file" | tee -a "$LOG"
  fi
done < "$WGET_LIST"

# === Download missing files ===
if [ -s "$TMPLIST" ]; then
  echo "📦 Downloading missing packages..." | tee -a "$LOG"
  wget --input-file="$TMPLIST" \
       --continue \
       --directory-prefix="$SRCROOT" \
       --tries=3 \
       --timeout=30 \
       2>&1 | tee -a "$LOG"
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
     2>&1 | tee -a "$LOG"

# === Verify integrity ===
if [ -f "$MD5_FILE" ]; then
  echo "🔐 Verifying checksums..." | tee -a "$LOG"
  cd "$SRCROOT"
  md5sum -c "$MD5_FILE" | tee -a "$LOG"
else
  echo "⚠️ No md5sums file found. Skipping integrity check." | tee -a "$LOG"
fi

echo "🎉 Fetch complete. Log saved to $LOG"
