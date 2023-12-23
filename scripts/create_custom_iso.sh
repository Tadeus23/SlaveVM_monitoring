#!/bin/bash

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install genisoimage if it's not installed
install_genisoimage() {
    if ! command_exists genisoimage; then
        echo "genisoimage is not installed. Installing it..."
        sudo apt update -y
        sudo apt install genisoimage -y
    fi
}

# Function to download and extract isolinux.bin
download_and_extract_isolinux() {
    local syslinux_archive="syslinux-6.03.tar.gz"
    local syslinux_extracted_dir="syslinux-6.03"

    if [ -f "$syslinux_extracted_dir/bios/core/isolinux.bin" ]; then
        echo "Using existing isolinux.bin from $syslinux_extracted_dir"
        cp "$syslinux_extracted_dir/bios/core/isolinux.bin" "$tmp_dir/"
    elif [ -f "$syslinux_archive" ]; then
        echo "Syslinux archive found locally. Extracting..."
        tar -xzf "$syslinux_archive"
        cp "$syslinux_extracted_dir/bios/core/isolinux.bin" "$tmp_dir/"
    elif [ ! -f "$tmp_dir/isolinux.bin" ]; then
        echo "Downloading Syslinux..."
        wget -O "$syslinux_archive" https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
        echo "Extracting Syslinux..."
        tar -xzf "$syslinux_archive"
        cp "$syslinux_extracted_dir/bios/core/isolinux.bin" "$tmp_dir/"
    else
        echo "isolinux.bin already exists in the temporary directory."
    fi
}

# Define your input and output file paths
ubuntu_iso="./ubuntu-22.04.3-desktop-amd64.iso"
output_dir="./custom_iso"
output_iso="$output_dir/custom_ubuntu.iso"

# Path to your preseed.cfg file
preseed_file="./preseed.cfg"

# Check if the input Ubuntu ISO file exists
if [ ! -f "$ubuntu_iso" ]; then
    echo "Error: Ubuntu ISO file not found at: $ubuntu_iso"
    exit 1
fi

# Check if the preseed.cfg file exists
if [ ! -f "$preseed_file" ]; then
    echo "Error: preseed.cfg file not found at: $preseed_file"
    exit 1
fi

# Create the output directory if it doesn't exist
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
    echo "Created output directory: $output_dir"
else
    echo "Output directory already exists: $output_dir"
fi

# Check if the custom ISO file already exists
if [ -f "$output_iso" ]; then
    echo "Custom ISO '$output_iso' already exists. Exiting script."
    exit 0
fi

# Create a directory to mount the original ISO
mnt_dir="/mnt/original_iso"
if [ ! -d "$mnt_dir" ]; then
    sudo mkdir -p "$mnt_dir"
    echo "Created mount directory: $mnt_dir"
else
    echo "Mount directory already exists: $mnt_dir"
fi

# Mount the original ISO to the directory
sudo mount -o loop "$ubuntu_iso" "$mnt_dir"

# Create a temporary directory to work in
tmp_dir=$(mktemp -d)
echo "Creating temporary working directory in $tmp_dir"

# Extract the contents of the original ISO to the temporary directory using 7z
echo "Extracting contents of the original ISO..."
7z x "$ubuntu_iso" -o"$tmp_dir"

# Copy the preseed.cfg file to the temporary directory
cp "$preseed_file" "$tmp_dir/preseed.cfg"

# Install genisoimage if not already installed
install_genisoimage

# Call the function to download and extract isolinux.bin
download_and_extract_isolinux

# Create the custom ISO using genisoimage
echo "Creating custom ISO..."
mkisofs -o "$output_iso" -b "isolinux.bin" -c "boot.cat" -no-emul-boot -input-charset utf-8 -boot-load-size 4 -boot-info-table -J -R -V "Custom Ubuntu" "$tmp_dir" > /dev/null 2>&1

echo "Custom ISO '$output_iso' has been created in $output_dir."

# Clean up temporary directory and unmount the original ISO
echo "Cleaning up..."
rm -r "$tmp_dir"
sudo umount "$mnt_dir"
rmdir "$mnt_dir"
