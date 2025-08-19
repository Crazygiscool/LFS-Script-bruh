#!/bin/bash
set -euo pipefail
ROOTFS=/workspaces/mydistro/chroot

sudo mount --bind /dev "$ROOTFS/dev"
sudo mount --bind /sys "$ROOTFS/sys"
sudo mount --bind /proc "$ROOTFS/proc"
sudo cp /etc/resolv.conf "$ROOTFS/etc/"

sudo chroot "$ROOTFS" /bin/bash -c "
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends systemd-sysv linux-image-generic \
    network-manager sudo dbus locales ca-certificates \
    xorg openbox picom lightdm xinit \
    squashfs-tools
apt-get clean
"

sudo umount "$ROOTFS/dev" || true
sudo umount "$ROOTFS/sys" || true
sudo umount "$ROOTFS/proc" || true

echo "Chroot setup complete."
