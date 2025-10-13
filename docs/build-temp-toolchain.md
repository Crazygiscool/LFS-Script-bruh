# 🧰 Chapter 5: Building the Temporary Toolchain

This chapter bootstraps a minimal toolchain inside `$LFS/tools` that will later be used to build the full system in a chroot environment. Each package is compiled in isolation to avoid host contamination.

---

## 📁 Directory Setup

Ensure you're working as the `lfs` user and `$LFS` is set:

```bash
export LFS=/mnt/lfs
```

Create a logging directory:

```bash
mkdir -p $LFS/sources/logs
```

---

## 🔄 General Build Pattern

Each package follows this modular pattern:

```bash
cd $LFS/sources
tar -xf package-name.tar.xz
cd package-name
mkdir -v build
cd build
../configure --prefix=$LFS/tools [additional flags]
make -j$(nproc) > $LFS/sources/logs/package-name-build.log 2>&1
make install >> $LFS/sources/logs/package-name-build.log 2>&1
```

You can wrap this in a script for reproducibility.

---

## 📦 Example: Binutils (First Package)

### 1. Extract and Enter

```bash
cd $LFS/sources
tar -xf binutils-2.42.tar.xz
cd binutils-2.42
mkdir -v build
cd build
```

### 2. Configure

```bash
../configure --prefix=$LFS/tools \
    --with-sysroot=$LFS \
    --target=$(uname -m)-lfs-linux-gnu \
    --disable-nls \
    --disable-werror
```

### 3. Build and Log

```bash
make -j$(nproc) > $LFS/sources/logs/binutils-build.log 2>&1
```

### 4. Install

```bash
make install >> $LFS/sources/logs/binutils-build.log 2>&1
```

---

## 🧪 Validate Toolchain (After GCC Pass 1)

After building GCC (pass 1), test the toolchain:

```bash
echo 'main(){}' > dummy.c
$LFS/tools/bin/$(uname -m)-lfs-linux-gnu-gcc dummy.c
readelf -l a.out | grep ': /tools'
```

You should see `/tools` in the output. If not, the toolchain is misconfigured.

---

## 🧰 Packages to Build in Chapter 5

Here’s the full list (LFS 12.0+):

| Package        | Purpose                              |
|----------------|--------------------------------------|
| Binutils       | Assembler and linker                 |
| GCC (pass 1)   | Initial compiler                     |
| Linux API Headers | Kernel interface headers         |
| Glibc          | C library                            |
| Libstdc++      | C++ standard library                 |
| M4, Ncurses, Bash, Coreutils, etc. | Basic utilities |

Each package has specific flags—refer to the [LFS book](https://www.linuxfromscratch.org/lfs/view/stable/) for exact instructions.

---

## 🧾 Modular Logging Strategy

To track provenance and enable restoration:

- Use `script` or `tee` to capture full sessions.
- Include environment snapshots (`env > build-env.txt`)
- Timestamp each build:

```bash
date > $LFS/sources/logs/binutils-start.txt
make -j$(nproc) | tee $LFS/sources/logs/binutils-build.log
date > $LFS/sources/logs/binutils-end.txt
```
