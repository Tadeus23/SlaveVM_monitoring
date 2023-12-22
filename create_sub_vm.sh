#!/bin/bash

# Check if the user provided the VM name as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <VMName>"
    exit 1
fi

# Define the VM name and path to the custom ISO
vm_name="$1"
custom_iso_file="./custom_ubuntu.iso"  # Replace with the path to your custom ISO

# Function to check if a file exists
file_exists() {
    if [ ! -f "$1" ]; then
        echo "File '$1' not found. Please provide a valid path."
        exit 1
    fi
}

# Check if the custom ISO file exists
file_exists "$custom_iso_file"

if VBoxManage showvminfo "$vm_name" >/dev/null 2>&1; then
    echo "VM '$vm_name' already exists."
else
    VBoxManage createvm --name "$vm_name" --ostype "Ubuntu_64" --register
    VBoxManage modifyvm "$vm_name" --memory 4000  # Memory in MB
    VBoxManage modifyvm "$vm_name" --cpus 2       # Number of CPUs
    VBoxManage modifyvm "$vm_name" --boot1 dvd --boot2 disk --boot3 none --boot4 none # Boot order
    VBoxManage modifyvm "$vm_name" --vram 23      # Video RAM in MB
    VBoxManage modifyvm "$vm_name" --graphicscontroller VMSVGA
    VBoxManage modifyvm "$vm_name" --vrde off     # Disable Remote Desktop Server
    VBoxManage modifyvm "$vm_name" --recording off # Disable Recording
    VBoxManage storagectl "$vm_name" --name "SATA Controller" --add sata --controller IntelAhci
    VBoxManage storageattach "$vm_name" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium "$custom_iso_file"
    VBoxManage createmedium disk --filename "$vm_name.vdi" --size 25000 --format VDI
    VBoxManage storageattach "$vm_name" --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium "$vm_name.vdi"
    VBoxManage modifyvm "$vm_name" --audio-driver "default" --audiocontroller "ac97"
    VBoxManage modifyvm "$vm_name" --nic1 "nat"
fi

# Start the VM
VBoxManage startvm "$vm_name" --type headless
