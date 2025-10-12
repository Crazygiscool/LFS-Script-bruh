# 🧱 Linux From Scratch: Next Steps Documentation

## 📁 1. Set the `$LFS` Environment Variable

This variable ensures all build tools and scripts target your LFS root.

```bash
export LFS=/mnt/lfs
```

To persist this across sessions, append it to your shell config:

for example, if you are using bash:

```bash
echo 'export LFS=/mnt/lfs' >> ~/.bashrc
source ~/.bashrc
```

---

## 🗂️ 2. Create the LFS Directory Structure

Establish the base filesystem layout inside your mounted image:

```bash
sudo mkdir -pv $LFS/{etc,var,lib64,usr/{bin,lib},tools}
sudo ln -sv usr/bin $LFS/bin
sudo ln -sv usr/lib $LFS/lib
```

---

## 👤 3. Create a Dedicated LFS User

This isolates your build environment and prevents accidental host system modifications.

```bash
sudo groupadd lfs
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
sudo passwd lfs
```

Grant ownership of the LFS directories:

```bash
sudo chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
```

Switch to the new user:

```bash
su - lfs
```

---

## 📦 4. Prepare the Source and Build Directories

Inside the `lfs` user session:

```bash
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
```

This directory will hold all source tarballs and build logs.

---

## 📚 5. Download LFS Packages and Patches

Visit [Linux From Scratch Downloads](https://www.linuxfromscratch.org/lfs/download.html) and download:

- All required packages
- All patches

Place them in `$LFS/sources`. You can use `wget` with a list file:

```bash
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
```

---

## 🧰 6. Build the Temporary Toolchain

This is the heart of Chapter 5 in the LFS book. You'll build:

- Binutils
- GCC (pass 1)
- Glibc headers
- Libstdc++
- And more…

Each package should be built inside `$LFS/tools`, using a consistent pattern:

```bash
tar -xf package-name.tar.xz
cd package-name
mkdir -v build
cd build
../configure --prefix=$LFS/tools ...
make
make install
```

Log each build to a dedicated file:

```bash
make > $LFS/sources/logs/binutils-build.log 2>&1
```

---

## 🧪 7. Validate the Toolchain

After building GCC and Binutils, verify the toolchain:

```bash
echo 'main(){}' > dummy.c
$LFS/tools/bin/gcc dummy.c
readelf -l a.out | grep ': /tools'
```

You should see `/tools` in the output. If not, the toolchain is misconfigured.

---

## 🧼 8. Clean Up and Prepare for Chroot

Once the temporary toolchain is complete:

- Remove build directories
- Ensure `$LFS/tools` is populated
- Prepare for entering the chroot environment

---

## 🔒 9. Enter the Chroot Environment

This isolates your build environment completely:

```bash
sudo chroot "$LFS" /tools/bin/env -i \
    HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h
```

---

## 🧱 10. Build the Final System (Chapter 6+)

Inside chroot, you'll:

- Rebuild the full toolchain
- Build core utilities (bash, coreutils, grep, etc.)
- Configure system files
- Set up boot scripts
- Install the kernel

---

## 🧾 11. Optional: Modular Logging and Provenance

To track build lineage and enable restoration-aware debugging:

- Create a `logs/` directory per package
- Include build flags, timestamps, and environment snapshots
- Use `tee` or `script` to capture full sessions

Example:

```bash
script -c "make && make install" $LFS/sources/logs/gcc-final.log
```
