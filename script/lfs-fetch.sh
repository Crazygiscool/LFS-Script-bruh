#!/bin/bash

# LFS Package Fetcher with Retry, Resume, and Integrity Check
# Author: Crazygiscool

set -e

export LFS=/mnt/lfs
export SRCROOT=$LFS/sources
export WGET_LIST=$SRCROOT/wget-list
export LOG=$SRCROOT/fetch.log
export TMPLIST=$SRCROOT/fetch-temp.list

echo "🌐 Starting LFS package fetch..." | tee -a "$LOG"
date | tee -a "$LOG"

# === Check prerequisites ===
if [ ! -f "$WGET_LIST" ]; then
  echo "❌ wget-list not found at $WGET_LIST" | tee -a "$LOG"
  exit 1
fi

mkdir -pv "$SRCROOT"

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

# === Optional: Check for updates (timestamp-based) ===
echo "🔄 Checking for upstream updates..." | tee -a "$LOG"
wget --input-file="$WGET_LIST" \
     --timestamping \
     --directory-prefix="$SRCROOT" \
     --tries=2 \
     --timeout=20 \
     2>&1 | tee -a "$LOG"

# === Optional: Verify integrity ===
MD5_FILE=$SRCROOT/md5sums
if [ -f "$MD5_FILE" ]; then
  echo "🔐 Verifying checksums..." | tee -a "$LOG"
  cd "$SRCROOT"
  md5sum -c "$MD5_FILE" | tee -a "$LOG"
else
  echo "⚠️ No md5sums file found. Skipping integrity check." | tee -a "$LOG"
fi

echo "🎉 Fetch complete. Log saved to $LOG"