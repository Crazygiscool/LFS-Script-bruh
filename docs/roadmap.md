# Linux From Scratch Roadmap

## ✅ Checkpoint Roadmap

### **✔ Chapter 2: Preparing the New Partition**

- [x] Created a dedicated LFS root (loopback image in your case)  
- [x] Formatted it as ext4  
- [x] Created and initialized swap (just needs `sudo chown root:root ~/lfs-swap.img && sudo swapon ~/lfs-swap.img`)  
- [x] Mounted root at `/mnt/lfs`  
- [x] Prepared `/mnt/lfs/sources` and `/mnt/lfs/tools`

👉 You are here.

---

### **➡ Chapter 3: Packages and Patches**

- Download all required source tarballs and patches into `/mnt/lfs/sources`  
- Verify checksums (important for reproducibility)  
- This ensures you have everything locally before you chroot

---

### **➡ Chapter 4: Final Host Preparation**

- Check your host system has all required build tools (`bash`, `binutils`, `gcc`, `make`, etc.)  
- Set up the `$LFS` environment variable in your shell:  
  
  ```bash

  export LFS=/mnt/lfs
  ```

- Add it to your shell startup if you want persistence

---

### **➡ Chapter 5: Constructing a Temporary System**

This is the **toolchain build**. You’ll build a minimal set of tools inside `$LFS/tools`:

1. Binutils (pass 1)  
2. GCC (pass 1)  
3. Linux API headers  
4. Glibc  
5. Binutils (pass 2)  
6. GCC (pass 2)  
7. Remaining temporary tools (including your ncurses script later)

At the end of Chapter 5, you’ll have a self‑contained toolchain in `/mnt/lfs/tools`.

---

### **➡ Chapter 6: Chroot and Build the Final System**

- Mount virtual filesystems (`/dev`, `/proc`, `/sys`, `/run`) into `$LFS`  
- Enter chroot with the new toolchain  
- Rebuild everything natively (this time into `/usr`, not `/tools`)  

---

### **➡ Chapter 7–10: System Configuration**

- Set up `/etc/fstab`  
- Configure networking, locales, and bootscripts  
- Install and configure GRUB (or systemd‑boot if you go UEFI)  

---

### **➡ Chapter 11: The Big Moment**

- Reboot into your brand‑new LFS system 🎉
