#!/bin/bash
set -euo pipefail
WORK=/workspaces/mydistro
ROOTFS=$WORK/chroot
IMAGE=$WORK/out
mkdir -p "$IMAGE"
# create filesystem.squashfs
sudo mksquashfs "$ROOTFS" "$IMAGE/filesystem.squashfs" -comp xz -Xbcj x86
# copy kernel and initrd from chroot (if present) — adjust paths as needed
# create minimal ISO tree
mkdir -p "$WORK/iso/boot/grub"
cp /usr/lib/grub/x86_64-efi/* "$WORK/iso/boot/grub/" 2>/dev/null || true
# create placeholder vmlinuz and initrd if you assemble them separately
# Generate ISO (simple; you may need to adapt for EFI boot)
sudo xorriso -as mkisofs -r -V "MyDistro" -o "$IMAGE/mydistro.iso" \
  -c boot.cat -b boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table "$WORK/iso"

echo "ISO assembled at $IMAGE/mydistro.iso"