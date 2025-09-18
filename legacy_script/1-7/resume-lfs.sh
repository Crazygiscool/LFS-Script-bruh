#!/bin/bash
set +e  # Continue on errors

# 🧠 Configurable mount point
export LFS=/mnt/lfs
export LFS_IMG=~/lfs.img
export LFS_LOOPDEV=""
export LFS_PARTITION="/dev/sdXn"  # Fallback if no image is used

# 🛠️ Toggles for each stage
RUN_HOST_SETUP=true
RUN_LFS_USER_SETUP=true
RUN_CHROOT_SETUP=true
RUN_POST_CHROOT_SETUP=true

# 🧹 Utility functions
log() { echo -e "\n🔹 $1"; }
run() { echo "➡️ $1"; eval "$1"; }

# 🔍 Detect loopback device if image exists
if [ -f "$LFS_IMG" ]; then
  LFS_LOOPDEV=$(losetup -j "$LFS_IMG" | cut -d: -f1)
  if [ -z "$LFS_LOOPDEV" ]; then
    log "🔄 Re-attaching loop device for $LFS_IMG"
    LFS_LOOPDEV=$(sudo losetup --find --show "$LFS_IMG")
  fi
  export LFS_PARTITION="$LFS_LOOPDEV"
  log "🔗 Using loop device: $LFS_PARTITION"
fi

# 🟢 Stage 1: Host Setup (Chapters 1–4)
if [ "$RUN_HOST_SETUP" = true ]; then
  log "Stage 1: Host Setup"
  run "umask 022"
  run "sudo mkdir -pv \$LFS"
  run "sudo mountpoint -q \$LFS || sudo mount \$LFS_PARTITION \$LFS"
fi

# 🔵 Stage 2: lfs User Setup (Chapters 5–6)
if [ "$RUN_LFS_USER_SETUP" = true ]; then
  log "Stage 2: lfs User Setup"
  run "sudo mountpoint -q \$LFS || sudo mount \$LFS_PARTITION \$LFS"
  if ! id lfs &>/dev/null; then
    run "sudo groupadd lfs"
    run "sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs"
  fi
  run "sudo chown -v lfs:lfs \$LFS"
  run "sudo su - lfs -c 'export LFS=\$LFS && echo \$LFS set for lfs user'"
fi

# 🟣 Stage 3: Chroot Setup (Chapter 7.3–7.4)
if [ "$RUN_CHROOT_SETUP" = true ]; then
  log "Stage 3: Chroot Setup"
  run "sudo mkdir -pv \$LFS/{dev,proc,sys,run}"
  run "sudo mkdir -pv \$LFS/dev/pts"
  run "sudo mountpoint -q \$LFS/dev || sudo mount --bind /dev \$LFS/dev"
  run "sudo mountpoint -q \$LFS/dev/pts || sudo mount --bind /dev/pts \$LFS/dev/pts"
  run "sudo mountpoint -q \$LFS/proc || sudo mount -t proc proc \$LFS/proc"
  run "sudo mountpoint -q \$LFS/sys || sudo mount -t sysfs sysfs \$LFS/sys"
  run "sudo mountpoint -q \$LFS/run || sudo mount -t tmpfs tmpfs \$LFS/run"

  log "Entering chroot..."
  sudo chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    /bin/bash --login
fi

# 🧩 Stage 4: Post-Chroot Essentials (Chapter 7.5–7.6)
if [ "$RUN_POST_CHROOT_SETUP" = true ]; then
  log "Stage 4: Post-Chroot Setup"
  run "sudo chroot \$LFS /bin/bash -c 'mkdir -pv /{boot,home,mnt,opt,srv,media/{floppy,cdrom},etc/{opt,sysconfig},lib/firmware,var/{log,mail,spool,tmp,cache,lib/{misc,locate}},usr/{local,share/{doc,info,locale,man},src},root && chmod 0750 /root && touch /var/log/{btmp,lastlog,faillog,wtmp}'"
  run "sudo chroot \$LFS /bin/bash -c 'ln -sv /proc/self/mounts /etc/mtab'"
  run "sudo chroot \$LFS /bin/bash -c 'cat > /etc/passwd << EOF
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
EOF'"
  run "sudo chroot \$LFS /bin/bash -c 'cat > /etc/group << EOF
root:x:0:
bin:x:1:
sys:x:2:
EOF'"
  run "sudo chroot \$LFS /bin/bash -c 'ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin'"
  run "sudo chroot \$LFS /bin/bash -c 'ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib'"
fi

log "🎉 Resume script complete. You can now continue building LFS."
