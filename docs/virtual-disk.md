## mounting in root to avoid fallocate issues

mkdir -p ~/LFS
cd ~/LFS
sudo fallocate -l 30G lfs-disk.img

## 2. Format it as ext4

sudo mkfs.ext4 ~/LFS/lfs-disk.img

## 3. Make a mount point

sudo mkdir -p /mnt/lfs

## 4. Mount it

sudo mount -o loop ~/LFS/lfs-disk.img /mnt/lfs

# swapfile

## 1. Create a 2GB swapfile (adjust size as needed)

sudo dd if=/dev/zero of=/mnt/lfs/swapfile bs=1M count=2048 status=progress

## 2. Secure permissions

sudo chmod 600 /mnt/lfs/swapfile

## 3. Format it as swap

sudo mkswap /mnt/lfs/swapfile

## 4. Enable it immediately

sudo swapon /mnt/lfs/swapfile
