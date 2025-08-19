#!/bin/bash
set -euo pipefail
ROOTFS=/workspaces/mydistro/chroot
RELEASE=jammy
MIRROR=http://archive.ubuntu.com/ubuntu

sudo rm -rf "$ROOTFS"
sudo mkdir -p "$ROOTFS"
sudo debootstrap --variant=minbase --arch=amd64 $RELEASE "$ROOTFS" $MIRROR

echo "Bootstrap complete."