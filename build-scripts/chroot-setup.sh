#!/bin/bash
set -euo pipefail

ROOTFS=/workspaces/REMOVED-OS/chroot

# Function to unmount filesystems
cleanup() {
    echo "Unmounting filesystems..."
    sudo umount "$ROOTFS/dev" || echo "Failed to unmount /dev"
    sudo umount "$ROOTFS/sys" || echo "Failed to unmount /sys"
    sudo umount "$ROOTFS/proc" || echo "Failed to unmount /proc"
}

# Set a trap to ensure cleanup on exit
trap cleanup EXIT

# Mount necessary filesystems
sudo mount --bind /dev "$ROOTFS/dev"
sudo mount --bind /sys "$ROOTFS/sys"
sudo mount --bind /proc "$ROOTFS/proc"
sudo cp /etc/resolv.conf "$ROOTFS/etc/"

# Chroot and install packages
sudo chroot "$ROOTFS" /bin/bash -c "
export DEBIAN_FRONTEND=noninteractive
echo 'deb http://archive.ubuntu.com/ubuntu/ noble main universe' > /etc/apt/sources.list
apt update
apt install -y --no-install-recommends locales
locale-gen en_US.UTF-8
apt install -y --no-install-recommends systemd-sysv linux-image-generic \
    network-manager sudo dbus ca-certificates \
    xorg openbox picom lightdm xinit \
    squashfs-tools
apt clean
"

echo "Chroot setup complete."
