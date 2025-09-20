# 🛠 How to Make a USB Visible in `lsblk` in WSL

## **Requirements**

- **WSL 2** (check with `wsl --version`)
- **Windows 11** or Windows 10 with the Store version of WSL
- The [`usbipd-win`](https://github.com/dorssel/usbipd-win) utility installed on Windows

---

## **Step 1 — Install usbipd-win on Windows**

Open **PowerShell as Administrator**:

```powershell
winget install --interactive --exact dorssel.usbipd-win
```

---

## **Step 2 — Install USB/IP tools in WSL**

Inside your WSL Ubuntu:

```bash
sudo apt update
sudo apt install linux-tools-generic hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/*-generic/usbip 20
```

---

## **Step 3 — List USB Devices in Windows**

In **PowerShell**:

```powershell
usbipd list
```

Example output:

```txt
BUSID  VID:PID    DEVICE
1-4    1058:0730  USB Mass Storage Device
```

Find your USB stick in the list.

---

## **Step 4 — Attach the USB to WSL**

Still in PowerShell:

```powershell
usbipd attach --busid 1-4 --wsl
```

Replace `1-4` with your USB’s BUSID.

---

## **Step 5 — Check in WSL**

Back in WSL:

```bash
lsblk
```

Now you should see something like:

```txt
sde   28.9G disk
└─sde1 28.9G part
```

From here, you can mount it like any normal Linux block device:

```bash
sudo mkdir -p /mnt/usb
sudo mount /dev/sde1 /mnt/usb
```

---

## **Step 6 — Detach When Done**

In PowerShell:

```powershell
usbipd detach --busid 1-4
```

---

💡 **Why this is needed:**  
The stock WSL kernel doesn’t enable USB mass storage by default, so the only way to get a USB to appear in `lsblk` is to explicitly pass it through from Windows using `usbipd-win`. Once attached, it behaves like a native Linux block device — perfect for LFS builds or raw disk operations.
