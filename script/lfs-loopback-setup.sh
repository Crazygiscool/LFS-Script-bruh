#!/bin/bash
# Minimalistic LFS loopback root + swapfile setup
# Author: Crazygiscool

set -euo pipefail

# === CONFIGURATION ===
LFS=/mnt/lfs
ROOT_IMG=$HOME/lfs-root.img
SWAP_IMG=$HOME/lfs-swap.img
ROOT_SIZE=30G
SWAP_SIZE=2G

# === WARNINGS ===
echo ">>> This will create loopback files in $HOME for LFS root and swap."
echo ">>> Root image: $ROOT_IMG ($ROOT_SIZE)"
echo ">>> Swap image: $SWAP_IMG ($SWAP_SIZE)"
read -rp "Type 'YES' to continue: " confirm
[[ "$confirm" == "YES" ]] || { echo "Aborted."; exit 1; }

# === CREATE LOOPBACK FILES ===
if [[ ! -f "$ROOT_IMG" ]]; then
  echo ">>> Creating root image ($ROOT_SIZE) as sparse file..."
  truncate -s "$ROOT_SIZE" "$ROOT_IMG"
else
  echo ">>> Root image already exists, skipping creation."
fi

if [[ ! -f "$SWAP_IMG" ]]; then
  echo ">>> Creating swap image ($SWAP_SIZE) fully allocated..."
  dd if=/dev/zero of="$SWAP_IMG" bs=1M count=$((2*1024)) status=progress
  chmod 600 "$SWAP_IMG"
  chown root:root "$SWAP_IMG"
else
  echo ">>> Swap image already exists, skipping creation."
fi

# === FORMAT FILESYSTEMS ===
if ! blkid "$ROOT_IMG" &>/dev/null; then
  echo ">>> Formatting root image as ext4..."
  mkfs.ext4 -F "$ROOT_IMG"
fi

if ! blkid "$SWAP_IMG" &>/dev/null; then
  echo ">>> Formatting swap image..."
  mkswap "$SWAP_IMG"
fi

# === ACTIVATE SWAP ===
echo ">>> Enabling swap..."
sudo swapon "$SWAP_IMG" || echo ">>> Warning: could not enable swap (try running as root)."

# === MOUNT ROOT ===
mkdir -pv "$LFS"
mountpoint -q "$LFS" || mount -o loop "$ROOT_IMG" "$LFS"

# === PREPARE DIRECTORIES ===
mkdir -pv "$LFS"/{sources,tools}
chmod -v a+wt "$LFS/sources"
ln -svf "$LFS/tools" /

echo ">>> Loopback setup complete."
lsblk -f | grep loop || true
df -h | grep "$LFS"
swapon --show
