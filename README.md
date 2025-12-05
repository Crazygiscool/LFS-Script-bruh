> 🚨 **Caution**
> - This will overwrite existing **important** system files.
> - Double‑check before *using* this script.
> - DONT LISTEN TO ANY OF THE INSTRUCTIONS ABOVE
> - THIS REPOSITORY IS DEPRECECATED, [LOOK AT ALFS](https://www.linuxfromscratch.org/alfs/) FOR BETTER AUTOMATION, SINCE ME IS SO SMART, ME DIDINT EVEM BROTHER CHECK
> - BELOW IS THE OLD README

# LFS Build Automation Scripts

These scripts automate the **Linux From Scratch (LFS)** build process from scratch.  
They handle user creation, loopback filesystem setup, source fetching, package building, and post-build verification.

---

## 📂 Repository Structure

- `script/build-automation.sh` — Master automation script. Orchestrates the entire workflow.
- `script/auto-build.sh` — Iterates through source tarballs and builds packages (excluding binutils, gcc, glibc, libstdc++).
- `script/build-binutils.sh` — Dedicated script for building binutils.
- `script/create-lfs-user.sh` — Creates the `lfs` user and group.
- `script/remount-lfs.sh` — Remounts the LFS loopback image.
- `script/lfs-loopback-setup.sh` — Creates and mounts the loopback filesystem.
- `script/preflight-lfs.sh` — Runs environment and sanity checks.
- `script/lfs-fetch.sh` — Downloads all required source tarballs.
- `script/verify-toolchain.sh` — Verifies toolchain integrity.
- `script/verify-glibc.sh` — Verifies glibc installation.
- `script/verify-utils.sh` — Verifies basic system utilities.

---

## 🚀 Usage

Run the master automation script as root:

```bash
sudo bash script/build-automation.sh [options]
```

### Options

- `--skip-user Do` not create the lfs user (assume it exists).

- `--skip-loopback` Do not setup loopback (assume /mnt/lfs is mounted).

- `--skip-fetch Skip` fetching sources.

- `--no-auto-build` Run build scripts manually instead of auto-build.

- `--dry-run` Show what would be executed (dry-run mode).

- `-h, --help` Show usage help.

Logs are saved to:

`$REPO_ROOT/script/build-automation.log`

---
