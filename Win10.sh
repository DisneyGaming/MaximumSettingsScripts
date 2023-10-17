#!/bin/bash

# Check if the user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as the root user. Please run it with administrator privileges."
    exit 1
fi


# Information message
echo "This script will help you create a customized Windows 10 ISO with VirtIO drivers."
echo "This script uses Mido to download the Windows 10 ISO."
echo "Mido only uses the Microsoft CDN to download the ISO."
echo "Press Enter to continue or Ctrl+C to cancel."
read

# Pre-requisites
apt-get install -y genisoimage wimtools wget

# Check if the script is running in the same folder as the Windows 10 ISO
if [ -f "win10x64.iso" ]; then
    ISO_PATH="./win10x64.iso"
else
    echo "Using Mido to download the Windows 10 ISO."
    echo "Press Enter to continue or Ctrl+C to cancel."
    read
    wget https://raw.githubusercontent.com/ElliotKillick/Mido/main/Mido.sh
    chmod +x Mido.sh
    ./Mido.sh win10x64
fi

# Download Virtio ISO
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso -O Virtio.iso

# Create a temporary folder
temp_dir=$(mktemp -d)
mkdir windows
mkdir drivers

# Mount the Windows 10 ISO
mount -o loop "$ISO_PATH" "$temp_dir"
cp -r "$temp_dir"/* windows/
umount "$temp_dir"

# Mount the Virtio ISO
mount -o loop Virtio.iso "$temp_dir"
cp -r "$temp_dir"/* drivers/
umount "$temp_dir"

# Modify the boot.wim file
wimmountrw windows/sources/boot.wim 1 "$temp_dir"
cp -r drivers "$temp_dir/"
wimunmount --commit "$temp_dir"
wimmountrw windows/sources/boot.wim 2 "$temp_dir"
cp -r drivers "$temp_dir/"
wimunmount --commit "$temp_dir"

# Compile the new ISO
mkisofs -allow-limited-size -o CustomWin10.iso -b boot/etfsboot.com -no-emul-boot -boot-load-seg 0x07C0 -boot-load-size 8 -iso-level 2 -J -l -D -N -joliet-long -relaxed-filenames -V "Custom Win10" -allow-lowercase -hide boot.catalog windows

# Cleanup
rm -rf "$temp_dir" windows drivers Virtio.iso

echo "The customized ISO has been created as 'CustomWin10.iso'."