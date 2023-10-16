#!/bin/bash

# Download Variables
win10url="http://tinycorelinux.net/4.x/armv7/a10Core.img.gz"
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
wget -O /tmp/win10.img.gz "$win10url" -q --show-progress
gzip -d /tmp/win10.img.gz
echo "Download Complete!"

# echo "Downloading VirtIO Drivers..."
# wget -O /tmp/virtio.iso "$VirtIO" -q --show-progress
# echo "Download Complete!"

# Begin Stage three (Flash ISO to Secondary Storage)
echo "Please input the location of your secondary HDD storage (e.g. /dev/sdb)"
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

dd if=/tmp/win10.img of=/dev/sdb1 status=progress
# dd if=/tmp/virtio.iso of=/dev/sdb2 status=progress

