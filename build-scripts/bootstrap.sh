#!/bin/bash
set -euo pipefail
ROOTFS=/workspaces/REMOVED-OS/chroot
RELEASE=noble
MIRROR=http://archive.ubuntu.com/ubuntu

sudo rm -rf "$ROOTFS"
sudo mkdir -p "$ROOTFS"
sudo debootstrap --variant=minbase --arch=amd64 $RELEASE "$ROOTFS" $MIRROR

echo "Bootstrap complete."