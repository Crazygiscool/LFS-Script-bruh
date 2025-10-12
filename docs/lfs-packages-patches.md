# 📦 Step-by-Step: Downloading LFS Packages and Patches

## 1. **Create the Sources Directory**

Inside your LFS partition:

```bash
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
```

This ensures all users can write to it, but only delete their own files.

---

## 2. **Download the Official Package List**

Get the `wget-list` file from the LFS website:

```bash
wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list -O $LFS/sources/wget-list
```

This file contains all the URLs for the required packages and patches.

---

## 3. **Download All Packages and Patches**

Use `wget` to fetch everything listed:

```bash
wget --input-file=$LFS/sources/wget-list --continue --directory-prefix=$LFS/sources
```

This will download all required tarballs and patches into `$LFS/sources`.

---

## 4. **Verify Integrity**

Download the MD5 checksums:

```bash
wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums -O $LFS/sources/md5sums
cd $LFS/sources
md5sum -c md5sums
```

This ensures all files are intact and match the expected versions.

---

## 5. **Manual Patch Access (Optional)**

If you want to browse or download patches manually, visit:

- [LFS 12.4 Patch List](https://www.linuxfromscratch.org/lfs/view/stable/chapter03/patches.html)
- [Patch Archive](https://www.linuxfromscratch.org/patches/downloads/)
