#!/bin/bash
set -euo pipefail

ROOTFS=/workspaces/REMOVED-OS/chroot

# Function to unmount filesystems
cleanup() {
    echo "Unmounting filesystems..."
    sudo umount "$ROOTFS/dev" || echo "Failed to unmount /dev"
    sudo umount "$ROOTFS/sys" || echo "Failed to unmount /sys"
    sudo umount "$ROOTFS/proc" || echo "Failed to unmount /proc"
}

# Set a trap to ensure cleanup on exit
trap cleanup EXIT

# Mount necessary filesystems
sudo mount --bind /dev "$ROOTFS/dev"
sudo mount --bind /sys "$ROOTFS/sys"
sudo mount --bind /proc "$ROOTFS/proc"
sudo cp /etc/resolv.conf "$ROOTFS/etc/"

# Chroot and install packages
sudo chroot "$ROOTFS" /bin/bash -c "
export DEBIAN_FRONTEND=noninteractive
echo 'deb http://archive.ubuntu.com/ubuntu/ noble main universe' > /etc/apt/sources.list
apt update
apt install -y --no-install-recommends locales
locale-gen en_US.UTF-8
apt install -y --no-install-recommends systemd-sysv linux-image-generic \
    network-manager sudo dbus ca-certificates \
    xorg openbox picom lightdm xinit \
    squashfs-tools sway wlroots wayland-utils wofi grim slurp mako swayidle swaylock swaybg wl-clipboard gatling \
    libnotify-bin libgtk-3-0 libxcb-composite0 \
    network-manager-gnome pipewire pipewire-audio-client-libraries wireplumber \
    pavucontrol nitrogen rofi waybar
apt clean

# Create Wayland session file
cat <<EOF > /usr/share/wayland-sessions/mydistro.desktop
[Desktop Entry]
Name=MyDistro (Sway)
Exec=sway
Type=Application
EOF

# Create basic Sway configuration
mkdir -p /etc/skel/.config/sway
cat <<EOF > /etc/skel/.config/sway/config
set \$mod Mod4
bindsym \$mod+Return exec alacritty
bindsym \$mod+d exec wofi --show drun
bindsym \$mod+Shift+q kill
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+r restart
bindsym \$mod+f fullscreen
bindsym \$mod+h focus left
bindsym \$mod+j focus down
bindsym \$mod+k focus up
bindsym \$mod+l focus right

# Autostart applications
exec_always --no-startup-id swaybg -i /usr/share/backgrounds/mywallpaper.jpg
exec_always --no-startup-id mako &
exec_always --no-startup-id wireplumber &
exec_always --no-startup-id nm-applet &
exec_always --no-startup-id /usr/bin/waybar &
EOF

# Create Waybar configuration
mkdir -p /etc/skel/.config/waybar
cat <<EOF > /etc/skel/.config/waybar/config
{
  "modules-left": ["sway/workspaces"],
  "modules-center": ["custom/launcher"],
  "modules-right": ["network", "pulseaudio", "battery", "clock"]
}
EOF

# Create Waybar CSS styling
cat <<EOF > /etc/skel/.config/waybar/style.css
/* Example CSS for Waybar */
* {
  font-family: "sans-serif";
  color: #ffffff; /* Change text color to white for branding */
}
#network {
  background-color: #282c34; /* Custom background color */
}
EOF

# Create Wofi configuration
mkdir -p /etc/skel/.config/wofi
cat <<EOF > /etc/skel/.config/wofi/style.css
/* Example CSS for Wofi */
* {
  font-family: "sans-serif";
  background-color: #1e1e1e; /* Dark background for Wofi */
  color: #ffffff; /* White text for visibility */
}
EOF

# Create Mako configuration
mkdir -p /etc/skel/.config/mako
cat <<EOF > /etc/skel/.config/mako/config
# Mako configuration example
font = "sans-serif 10"
EOF

# Add swayidle command to Sway config for locking
cat <<EOF >> /etc/skel/.config/sway/config
swayidle -w \
  timeout 300 'swaylock -f -c 000000' \
  resume 'swaylock -f -c 000000' &
EOF