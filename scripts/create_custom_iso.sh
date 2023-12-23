#!/bin/bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_genisoimage() {
    if ! command_exists genisoimage; then
        echo "genisoimage is not installed. Installing it..."
        sudo apt update -y
        sudo apt install genisoimage -y
    fi
}

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

clean_up() {
    echo "Cleaning up..."

    sudo rm -r "$tmp_dir"

    sudo umount "$mnt_dir"
    sudo rmdir "$mnt_dir"

    local syslinux_archive="syslinux-6.03.tar.gz"
    local syslinux_extracted_dir="syslinux-6.03"
    sudo rm -f "$syslinux_archive"
    sudo rm -rf "$syslinux_extracted_dir"

    echo "Cleanup complete."
}

ubuntu_iso="../ubuntu-22.04.3-desktop-amd64.iso"
output_dir="./custom_iso"
output_iso="$output_dir/custom_ubuntu.iso"

preseed_file="../config/preseed.cfg"

if [ ! -f "$ubuntu_iso" ]; then
    echo "Error: Ubuntu ISO file not found at: $ubuntu_iso"
    exit 1
fi

if [ ! -f "$preseed_file" ]; then
    echo "Error: preseed.cfg file not found at: $preseed_file"
    exit 1
fi

if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
    chmod 777 "$output_dir"
    echo "Created output directory: $output_dir"
else
    echo "Output directory already exists: $output_dir"
fi

if [ -f "$output_iso" ]; then
    echo "Custom ISO '$output_iso' already exists. Exiting script."
    exit 0
fi

mnt_dir="/mnt/original_iso"
if [ ! -d "$mnt_dir" ]; then
    sudo mkdir -p "$mnt_dir"
    echo "Created mount directory: $mnt_dir"
else
    echo "Mount directory already exists: $mnt_dir"
fi

sudo mount -o loop "$ubuntu_iso" "$mnt_dir"

tmp_dir=$(mktemp -d)
echo "Creating temporary working directory in $tmp_dir"

echo "Extracting contents of the original ISO..."
7z x "$ubuntu_iso" -o"$tmp_dir"

cp "$preseed_file" "$tmp_dir/preseed.cfg"

install_genisoimage

download_and_extract_isolinux

echo "Creating custom ISO..."
mkisofs -o "$output_iso" -b "isolinux.bin" -c "boot.cat" -no-emul-boot -input-charset utf-8 -boot-load-size 4 -boot-info-table -J -R -V "Custom Ubuntu" "$tmp_dir" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Custom ISO '$output_iso' has been created in $output_dir."
    clean_up
else
    echo "Failed to create custom ISO."
    clean_up
    exit 1
fi