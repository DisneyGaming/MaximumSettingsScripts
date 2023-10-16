#!/bin/bash

# Download Variables
win10url="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso"
# VirtIO="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"

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
# Begin Stage one (Download Windows 10 ISO & VirtIO Drivers)
echo "Downloading Windows 10 ISO..."
wget -O /tmp/win10.iso "$win10url" -q --show-progress
echo "Download Complete!"

# echo "Downloading VirtIO Drivers..."
# wget -O /tmp/virtio.iso "$VirtIO" -q --show-progress
# echo "Download Complete!"

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
wait 2
# cat <<EOF >> /etc/grub.d/40_custom
# menuentry "Windows 10" {
#     insmod part_msdos
#     insmod part_gpt
#     insmod fat
#     set root='(hd1)'
#     drivemap -s (hd0) ${root}
#     chainloader +1
# }
# EOF
echo "Adding Windows 10 to GRUB..."
cat <<EOF >> /etc/grub.d/40_custom
menuentry "Install on sdb1" {
    set root=(hd1,1)
    linux /boot/vmlinuz root=/dev/sdb1 ro quiet splash
    initrd /boot/initrd.img
}
EOF
update-grub

