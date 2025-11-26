# LFS Build Automation Guide

Complete automation scripts for building a Linux From Scratch (LFS 12.4) system.

## Quick Start

**One command to build everything (requires sudo):**

```bash
sudo bash script/build-automation.sh
```

This will:
1. ✅ Pre-flight checks on all scripts and resources
2. ✅ Create the `lfs` user (if missing)
3. ✅ Setup loopback LFS filesystem (if not mounted)
4. ✅ Run preflight environment checks
5. ✅ Fetch LFS 12.4 sources from the official mirrors
6. ✅ Auto-build all packages
7. ✅ Verify toolchain and glibc

**Note:** `run-all.sh` is now integrated into `build-automation.sh` — it's the recommended primary script.

---

## Scripts Overview

### Master Automation Script (PRIMARY - USE THIS)
- **`build-automation.sh`** — Complete end-to-end workflow orchestrator
  - ✅ Pre-execution checks on all scripts and resources
  - ✅ Validates LFS mount, directories, permissions
  - ✅ Verifies wget, required tools availability
  - ✅ Checks for source tarballs before building
  - Creates `lfs` user (if needed)
  - Sets up loopback filesystem (if needed)
  - Runs all build steps
  - Logs to `script/build-automation.log`
  - **Usage:** `sudo bash script/build-automation.sh [options]`
  - **This is the recommended primary script**

### User & Environment Setup
- **`create-lfs-user.sh`** — Create `lfs` user and group
  - Idempotent: safe to run multiple times
  - Adds to sudoers automatically
  - **Usage:** `sudo bash script/create-lfs-user.sh`
  - **Options:** `--uid`, `--home`, `--shell`, `--sudo`, `--passwd`

- **`switch-to-lfs.sh`** — Create `lfs` user (if needed) and switch to it
  - Creates user, sets sudoers, fixes ownership
  - Runs interactive login shell as `lfs`
  - **Usage:** `bash script/switch-to-lfs.sh`

### Loopback Filesystem
- **`lfs-loopback-setup.sh`** — Create and mount LFS loopback images
  - Creates 30GB root image and 2GB swap image in `$HOME`
  - Formats as ext4/swap and mounts to `/mnt/lfs`
  - Sets up `/mnt/lfs/{sources,tools}`
  - **Usage:** `sudo bash script/lfs-loopback-setup.sh`
  - **Requires:** Confirmation prompt (type `YES`)

- **`remount-lfs.sh`** — Remount existing LFS loopback image
  - Useful for re-mounting after reboot
  - **Usage:** `bash script/remount-lfs.sh`

### Checks & Validation
- **`version-check.sh`** — Verify host tools meet LFS requirements
  - Checks: gcc, make, perl, python, kernel version, etc.
  - Tests g++ compilation
  - **Usage:** `bash script/version-check.sh`

- **`preflight-lfs.sh`** — Preflight environment validation
  - Verifies `/mnt/lfs` mount
  - Creates and fixes ownership of sources/logs directories
  - Tests write access as `lfs` user
  - **Usage:** `bash script/preflight-lfs.sh`

### Source Management
- **`lfs-fetch.sh`** — Fetch all LFS 12.4 sources from official mirrors
  - Downloads wget-list and md5sums
  - Downloads missing packages
  - Verifies checksums
  - Logs to `$LFS/sources/fetch.log`
  - **Usage:** `bash script/lfs-fetch.sh`

- **`fetch-gcc-prereqs.sh`** — Download GCC prerequisites (gmp, mpfr, mpc)
  - Used by `build-gcc.sh`
  - **Usage:** `bash script/fetch-gcc-prereqs.sh`

### Build Scripts
- **`auto-build.sh`** — Automatic package build orchestrator
  - Finds all `*.tar.*` in `$LFS/sources`
  - Handles special cases: binutils, gcc, linux, glibc, libstdc++
  - Logs build output to `$LFS/sources/logs/<package>/`
  - Creates build manifest
  - **Usage:** `bash script/auto-build.sh`

- **`build-linux-headers.sh`** — Build Linux API headers
  - Installs headers to `$LFS/usr/include`
  - **Usage:** `bash script/build-linux-headers.sh`

- **`build-gcc.sh`** — Build GCC cross-compiler
  - Nests prerequisites (gmp, mpfr, mpc)
  - Installs to `$LFS/tools`
  - **Usage:** `bash script/build-gcc.sh`

- **`build-glibc.sh`** — Build GNU C Library
  - Installs to `$LFS/usr/lib`
  - **Usage:** `bash script/build-glibc.sh`

- **`build-ncurses-temp.sh`** — Build Ncurses (temporary tools)
  - For temporary cross-compilation toolchain
  - **Usage:** `bash script/build-ncurses-temp.sh`

- **`build-ncurses.sh`** — Build Ncurses (final)
  - Final Ncurses build
  - **Usage:** `bash script/build-ncurses.sh`

### Verification
- **`verify-toolchain.sh`** — Verify cross-compilation toolchain
  - Checks for required binaries (ar, as, ld, nm, strip, gcc)
  - Tests cross-compilation
  - **Usage:** `bash script/verify-toolchain.sh`

- **`verify-glibc.sh`** — Verify glibc installation
  - Checks startup objects (Scrt1.o, crti.o, crtn.o)
  - Tests libc.so presence
  - Tests compilation against glibc
  - **Usage:** `bash script/verify-glibc.sh`

### Chroot & System Setup
- **`chroot-bootstrap.sh`** — Bootstrap chroot environment
  - Sets up `/dev`, `/proc`, `/sys` for chroot
  - Mounts virtual filesystems
  - **Usage:** `sudo bash script/chroot-bootstrap.sh`

- **`chroot-entry.sh`** — Enter chroot environment
  - Enters chroot and starts interactive shell
  - **Usage:** `sudo bash script/chroot-entry.sh`

- **`chroot-exit-cleanup.sh`** — Exit and clean up chroot
  - Unmounts virtual filesystems
  - Cleans up chroot binds
  - **Usage:** `sudo bash script/chroot-exit-cleanup.sh`

---

## Typical Workflow

### Option 1: Full Automation (Recommended)
```bash
# Run everything in one command
sudo bash script/build-automation.sh
```

### Option 2: Manual Step-by-Step
```bash
# 1. Check host tools
bash script/version-check.sh

# 2. Create lfs user
sudo bash script/create-lfs-user.sh

# 3. Setup loopback filesystem
sudo bash script/lfs-loopback-setup.sh

# 4. Run preflight
bash script/preflight-lfs.sh

# 5. Fetch sources
bash script/lfs-fetch.sh

# 6. Switch to lfs user and build
bash script/switch-to-lfs.sh
# Then inside lfs shell:
bash script/auto-build.sh

# 7. Verify
bash script/verify-toolchain.sh
bash script/verify-glibc.sh
```

### Option 3: Skip Already-Done Steps
```bash
# Skip user creation if lfs already exists
sudo bash script/build-automation.sh --skip-user

# Skip loopback if /mnt/lfs is already mounted
sudo bash script/build-automation.sh --skip-loopback

# Skip source fetching if already downloaded
sudo bash script/build-automation.sh --skip-fetch

# Run individual build scripts manually
sudo bash script/build-automation.sh --no-auto-build
```

---

## Environment Variables

The build scripts use these key variables:

- **`LFS`** — LFS mount point (default: `/mnt/lfs`)
- **`SRCROOT`** — Source directory (default: `$LFS/sources`)
- **`LOGROOT`** — Log directory (default: `$SRCROOT/logs`)
- **`USERNAME`** — Build user (default: `lfs`)
- **`TARGET`** — Cross-compile target triple (auto-detected from `uname -m`)
- **`NPROC`** — Number of parallel jobs (auto-detected from `nproc`)

Export these before running scripts if you want to override defaults:
```bash
export LFS=/custom/lfs/path
export NPROC=8
bash script/auto-build.sh
```

---

## Logs & Debugging

All scripts produce detailed logs:

- **Main automation log:** `script/build-automation.log`
- **Remount log:** `$HOME/LFS/remount.log`
- **Fetch log:** `$LFS/sources/fetch.log`
- **Build manifest:** `$LFS/sources/build-manifest.txt`
- **Per-package logs:** `$LFS/sources/logs/<package>/{configure,make,install}.log`

View logs in real-time:
```bash
tail -f script/build-automation.log
tail -f /mnt/lfs/sources/fetch.log
tail -f /mnt/lfs/sources/logs/gcc-*/make.log
```

---

## Troubleshooting

### ❌ "User 'lfs' does not exist"
Run user creation:
```bash
sudo bash script/create-lfs-user.sh
```

### ❌ "Disk image not found: /home/user/lfs-disk.img"
Create loopback image:
```bash
sudo bash script/lfs-loopback-setup.sh
```

### ❌ "Permission denied" on `/mnt/lfs/sources`
Fix ownership:
```bash
sudo chown -R lfs:lfs /mnt/lfs/sources
```

### ❌ "Cannot find gcc prerequisites"
Fetch GCC prerequisites:
```bash
bash script/fetch-gcc-prereqs.sh
```

### ⚠️ "Swapfile not active"
Enable swap:
```bash
sudo swapon /mnt/lfs/swapfile
# or if using loopback swap:
sudo swapon /root/lfs-swap.img
```

### ⚠️ Build fails partway through
Check logs:
```bash
tail -100 /mnt/lfs/sources/logs/<package>/make.log
```

Then resume (auto-build skips already-built packages):
```bash
bash script/auto-build.sh
```

---

## Configuration

Edit scripts directly to customize:

- **Loopback sizes:** Edit `lfs-loopback-setup.sh` — `ROOT_SIZE` and `SWAP_SIZE`
- **LFS mount point:** Edit `build-automation.sh` — `export LFS=/custom/path`
- **Parallel jobs:** Set `NPROC=<num>` before running build scripts
- **Kernel version requirement:** Edit `version-check.sh` — `ver_kernel 5.4`

---

## Safety & Idempotency

All scripts are designed to be:
- **Idempotent:** Safe to run multiple times (skips completed steps)
- **Non-destructive:** Checks before deleting/overwriting
- **Incremental:** Resumes from where it left off
- **Logged:** Detailed logs for debugging

Example: Run `auto-build.sh` multiple times—it skips already-built packages.

---

## Requirements

### Host System
- **OS:** Linux (tested on Arch, Ubuntu, Fedora)
- **Kernel:** 5.4+
- **Tools:** gcc, make, binutils, perl, python3, tar, wget, patch, m4, sed, gawk, diff, find, grep, gzip, texinfo, xz
- **Utilities:** sudo, mount, losetup, mkfs.ext4, mkswap, swapon

### Disk Space
- **Root image:** 30GB (configurable, sparse file)
- **Swap image:** 2GB (configurable)
- **Sources:** ~2GB
- **Total:** ~34GB recommended

### Memory
- **RAM:** 2GB minimum, 4GB+ recommended
- **Swap:** 2GB (configured automatically)

---

## References

- **LFS Book:** https://www.linuxfromscratch.org/lfs/view/12.4-systemd/
- **LFS Downloads:** https://www.linuxfromscratch.org/lfs/downloads/12.4-systemd/

---

## License

These automation scripts are provided as-is. LFS itself is available under the Creative Commons License.

---

## Support

For issues:
1. Check the logs (see "Logs & Debugging" section)
2. Verify host tools (`bash script/version-check.sh`)
3. Review LFS Book chapter for the failing step
4. Check disk space: `df -h /mnt/lfs`

