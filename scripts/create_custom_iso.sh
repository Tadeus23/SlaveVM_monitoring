#!/bin/bash

set -e  # Exit on error


download_and_extract_isolinux() {
    local syslinux_archive="syslinux-6.03.tar.gz"
    local syslinux_extracted_dir="syslinux-6.03"
    local isolinux_dest_dir="$EXTRACT_DIR/isolinux"

    mkdir -p "$isolinux_dest_dir"

    if [ -f "$syslinux_extracted_dir/bios/core/isolinux.bin" ]; then
        echo "Using existing isolinux.bin from $syslinux_extracted_dir"
    elif [ -f "$syslinux_archive" ]; then
        echo "Syslinux archive found locally. Extracting..."
        tar -xzf "$syslinux_archive"
    elif [ ! -f "$isolinux_dest_dir/isolinux.bin" ]; then
        echo "Downloading Syslinux..."
        wget -O "$syslinux_archive" https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
        echo "Extracting Syslinux..."
        tar -xzf "$syslinux_archive"
    else

        echo "isolinux.bin already exists in the temporary directory."
    fi

    cp "$syslinux_extracted_dir/bios/core/isolinux.bin" "$isolinux_dest_dir/"
}

# Function to check if a specific command is installed, and install it if not
check_and_install_command() {
    local cmd=$1
    local package=${2:-$1}  # If package name is not provided, use cmd name

    if ! command -v $cmd &> /dev/null; then
        echo "Command $cmd not found. Attempting to install $package..."
        apt-get update && apt-get install -y $package
    fi
}


# Variables
ISO="./ubuntu-22.04.3-desktop-amd64.iso"
MOUNT_POINT="/mnt/ubuntu-iso"
EXTRACT_DIR="/tmp/ubuntu-iso"
CUSTOM_DIR="/tmp/custom-ubuntu"
NEW_ISO="custom-ubuntu-22.04-desktop-amd64.iso"
OUTPUT_DIR="./custom"
# Clean up
echo "Cleaning up..."
if mount | grep -q "on $MOUNT_POINT type"; then
    umount $MOUNT_POINT
fi
rm -rf $MOUNT_POINT $EXTRACT_DIR $CUSTOM_DIR

# Check for required commands
check_and_install_command "mount"
check_and_install_command "rsync"
check_and_install_command "unsquashfs"
check_and_install_command "mksquashfs"
check_and_install_command "genisoimage"

# Ensure running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if ISO file exists
if [ ! -f "$ISO" ]; then
    echo "ISO file not found: $ISO" 1>&2
    exit 1
fi

# Step 1: Check if the ISO is already mounted
echo "Checking if ISO is already mounted..."
if mount | grep -q "on $MOUNT_POINT type"; then
    echo "ISO already mounted. Skipping the mount step."
else
    echo "Mounting ISO..."
    mkdir -p $MOUNT_POINT
    chmod 777 $MOUNT_POINT
    mount -o loop $ISO $MOUNT_POINT
fi

# Step 2: Copy the ISO contents to a working directory
echo "Copying ISO contents..."
mkdir -p $EXTRACT_DIR
chmod 777 $EXTRACT_DIR
rsync -av $MOUNT_POINT/ $EXTRACT_DIR

# Step 3: Extract the SquashFS filesystem
echo "Extracting SquashFS filesystem..."
mkdir -p $CUSTOM_DIR
chmod 777 $CUSTOM_DIR
unsquashfs -d $CUSTOM_DIR/squashfs-root $EXTRACT_DIR/casper/filesystem.squashfs

# Copy host's DNS settings
cp /etc/resolv.conf $CUSTOM_DIR/squashfs-root/etc/

# Step 4: Chroot into the extracted filesystem
echo "Entering chroot environment..."
mount --bind /dev $CUSTOM_DIR/squashfs-root/dev
mount --bind /proc $CUSTOM_DIR/squashfs-root/proc
mount --bind /sys $CUSTOM_DIR/squashfs-root/sys
chroot $CUSTOM_DIR/squashfs-root /bin/bash <<EOF

# Generate and update locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Customization commands go here
# For example, setting timezone and locale
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Install additional packages or remove packages
apt-get update
apt-get install -y vim  # example package
apt-get clean

# Modify settings, add users, etc.

EOF

# Exit chroot
echo "Exiting chroot..."

# Unmount special filesystems
umount $CUSTOM_DIR/squashfs-root/{sys,proc,dev}

# Step 5: Repackage the modified filesystem
echo "Repackaging the modified filesystem..."
mksquashfs $CUSTOM_DIR/squashfs-root $EXTRACT_DIR/casper/filesystem.squashfs -noappend

download_and_extract_isolinux

# Step 6: Create the new ISO
echo "Creating new ISO..."
cd $EXTRACT_DIR
mkdir $OUTPUT_DIR
genisoimage -r -V "Custom Ubuntu 22.04" -cache-inodes -J -l \
            -b isolinux/isolinux.bin \
            -c isolinux/boot.cat \
            -no-emul-boot -boot-load-size 4 -boot-info-table \
            -o "$OUTPUT_DIR/$NEW_ISO" .

# Ensure ISO creation was successful
if [ -f "../$NEW_ISO" ]; then
    echo "Custom ISO created: ../$NEW_ISO"
else
    echo "Failed to create custom ISO."
    exit 1
fi

# Clean up
echo "Cleaning up..."
if mount | grep -q "on $MOUNT_POINT type"; then
    umount $MOUNT_POINT
fi
# Only remove the directories but not the newly created ISO
#rm -rf $MOUNT_POINT $EXTRACT_DIR $CUSTOM_DIR
