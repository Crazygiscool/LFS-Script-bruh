# Script Architecture & Usage Guide

## Primary Entry Point

**`build-automation.sh`** is the main automation script. Use this for all builds.

```bash
sudo bash script/build-automation.sh
```

## What Changed

Previously, `run-all.sh` was the primary user-facing script. It has now been **integrated and superseded** by `build-automation.sh`.

### Key Improvements in build-automation.sh

1. **Pre-execution Validation**
   - ✅ Checks script existence before running
   - ✅ Verifies required tools (wget, etc.)
   - ✅ Validates mount points and directories
   - ✅ Confirms file permissions
   - ✅ Tests write access before operations

2. **Better Error Messages**
   - Clear feedback on what's missing
   - Suggestions for fixes
   - Aborts early with helpful context

3. **Status Visibility**
   - Shows mount usage (`df` output)
   - Displays user IDs and sudoers status
   - Reports what's being created vs. already exists
   - Lists missing vs. present packages

## When to Use Which Script

| Task | Script | How |
|------|--------|-----|
| **Full automation** | `build-automation.sh` | `sudo bash script/build-automation.sh` |
| **Just user creation** | `create-lfs-user.sh` | `sudo bash script/create-lfs-user.sh` |
| **Create loopback FS** | `lfs-loopback-setup.sh` | `sudo bash script/lfs-loopback-setup.sh` |
| **Remount after reboot** | `remount-lfs.sh` | `bash script/remount-lfs.sh` |
| **Check tools** | `version-check.sh` | `bash script/version-check.sh` |
| **Manual builds** | Individual `build-*.sh` | `bash script/build-gcc.sh`, etc. |

## Typical Workflows

### Workflow 1: One-Command Full Automation (Recommended)
```bash
sudo bash script/build-automation.sh
```
Does everything: creates user, mounts, fetches, builds, verifies.

### Workflow 2: Step-by-Step (for debugging)
```bash
# Check host tools
bash script/version-check.sh

# Setup
sudo bash script/build-automation.sh --skip-fetch

# Then manually
su - lfs
bash script/auto-build.sh
```

### Workflow 3: Resume After Failure
```bash
# Fix the issue, then resume
sudo bash script/build-automation.sh --skip-user --skip-loopback
```

## Script Hierarchy

```
build-automation.sh (master)
├── create-lfs-user.sh
├── lfs-loopback-setup.sh
├── remount-lfs.sh
├── preflight-lfs.sh
├── version-check.sh
├── lfs-fetch.sh
├── auto-build.sh
│   ├── build-linux-headers.sh
│   ├── build-gcc.sh
│   ├── build-glibc.sh
│   └── build-ncurses*.sh
└── verify-*.sh
    ├── verify-toolchain.sh
    └── verify-glibc.sh
```

## Deprecation Notice

⚠️ **`run-all.sh` is now deprecated** in favor of `build-automation.sh`.

If you have existing calls to `run-all.sh`, migrate to:
```bash
# Old (still works but no longer maintained):
bash script/run-all.sh --yes

# New (recommended):
sudo bash script/build-automation.sh
```

The key difference:
- `run-all.sh` required manual user creation and did not have pre-execution checks
- `build-automation.sh` creates the user, validates everything, and requires sudo

## Pre-Execution Checks in build-automation.sh

For each step, the script now:

1. **User Creation**
   - Verifies `create-lfs-user.sh` exists
   - Checks if lfs user already exists
   - Ensures sudoers file is configured

2. **Loopback Setup**
   - Checks if LFS is already mounted
   - Verifies mount scripts exist
   - Tries remount first, then loopback setup
   - Validates mount succeeded

3. **Preflight**
   - Ensures LFS mount exists
   - Runs preflight checks

4. **Fetch**
   - Verifies wget is available
   - Checks sources directory writability
   - Confirms fetch script exists

5. **Build**
   - Verifies tarballs exist in sources
   - Ensures lfs user exists
   - Confirms build script exists

6. **Verification**
   - Checks verification scripts exist
   - Reports if missing (non-fatal)

## Options for build-automation.sh

```bash
# Full run with all steps
sudo bash script/build-automation.sh

# Skip user creation (if lfs already exists)
sudo bash script/build-automation.sh --skip-user

# Skip loopback (if /mnt/lfs already mounted)
sudo bash script/build-automation.sh --skip-loopback

# Skip source download (if already fetched)
sudo bash script/build-automation.sh --skip-fetch

# Run build scripts manually instead of auto-build
sudo bash script/build-automation.sh --no-auto-build

# Dry-run: see what would execute
sudo bash script/build-automation.sh --dry-run

# Combine options
sudo bash script/build-automation.sh --skip-user --skip-loopback --dry-run
```

## Logging

All execution is logged to `script/build-automation.log`:

```bash
# Watch logs in real-time
tail -f script/build-automation.log

# View full log after run
cat script/build-automation.log
```

Individual build steps also create logs in `/mnt/lfs/sources/logs/`.

## Summary

- ✅ Use `build-automation.sh` for all builds
- ✅ It validates everything before executing
- ✅ Create user automatically
- ✅ Setup loopback if needed
- ✅ Full end-to-end workflow
- ✅ Comprehensive error checking
- ✅ Easy to resume if interrupted

