#!/bin/bash

# Download Variables
# win10url="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso"
win10url="http://148.197.76.111:5500/Win10.iso"

# Variables Linux
wget=/usr/bin/wget

# Check if script is running as EUID 0 (root). Exit if not
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
    fi

clear
echo "This script is experimental. Do you wish to continue? (y/n)"
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Continuing..."
    else
    echo "Exiting..."
    exit
    fi

# Prerequisites
echo "Installing Prerequisites..."
apt update
apt install wget parted -y

if [ -f "CustomWin10.iso" ]; then
    ISO_PATH="./CustomWin10.iso"
else
    exit 1
fi
# Begin Stage three (Flash ISO to Secondary Storage)

# echo "Please input the location of your secondary HDD storage (e.g. /dev/sdb)"
# read HDDLocation

echo "WARNING: This will erase all data on the drive!"
echo "Do you wish to proceed? (y/n)"
read FormatAnswer

if [ "$FormatAnswer" != "${FormatAnswer#[Yy]}" ] ;then
    echo "Flashing ISO..."
    else
    echo "Exiting..."
    exit
    fi

umount /dev/sdb
sleep 2
parted -a optimal /dev/sdb mkpart primary 0% 75%
parted -a optimal /dev/sdb mkpart primary 75% 100%

dd if=/tmp/win10.iso of=/dev/sdb1 status=progress
# dd if=/tmp/virtio.iso of=/dev/sdb2 status=progress

# Begin Stage four (Add Windows 10 to GRUB)
echo "Enabling GRUB..."
sudo sed -i 's/GRUB_TIMEOUT_STYLE=/#GRUB_TIMEOUT_STYLE=/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT=/GRUB_TIMEOUT=5/' /etc/default/grub
echo "GRUB Enabled!"
sleep 2

echo "Adding Windows 10 to GRUB..."
cat <<EOF >> /etc/grub.d/40_custom
menuentry "Load me for Windows 10!" {
set root=(hd1,msdos1) # Adds Windows 10 Installer via Chainloader of the GRUB loader.
chainloader /efi/boot/bootaa64.efi
boot
}
EOF
update-grub

