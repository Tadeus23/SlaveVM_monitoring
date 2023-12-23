#!/bin/bash

# Check if the user provided the VM name as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <No argument provided>"
    exit 1
fi

# Verify that VirtualBox is installed
if ! VBoxManage --version >/dev/null 2>&1; then
    echo "VirtualBox is not installed or not in your PATH. Please install VirtualBox first."
    exit 1
fi

# Specify the VM name as an argument
vm_name="$1"
echo VM name provided as an argument
echo

# Create a sub-directory for exporting files (if it doesn't exist)
export_dir="exported_files"
mkdir -p "$export_dir"

# Export the VM as an OVF file in the sub-directory
ovf_file="${export_dir}/${vm_name}.ovf"
VBoxManage export "$vm_name" --output "$ovf_file"

# Export the VM's virtual hard disk as a VMDK file in the sub-directory
vmdk_file="${export_dir}/${vm_name}.vmdk"
VBoxManage clonehd "$(VBoxManage showvminfo --machinereadable "$vm_name" | grep "SATA Controller-0-0")" "$vmdk_file" --format VMDK

echo "Exported VM '$vm_name' to $ovf_file and $vmdk_file in the '$export_dir' sub-directory successfully."

set +x