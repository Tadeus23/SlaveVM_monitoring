import subprocess
import getpass
import shlex
import os
from request_pass_gui import provide_pass


def create_custom_iso():
    try:
        # Specify the path to your custom ISO creation script
        custom_iso_script_path = "./create_custom_iso.sh"

        # Check if the custom ISO file already exists
        custom_iso_file = "custom_ubuntu.iso"
        if os.path.exists(custom_iso_file):
            print(f"Create.py: Custom ISO '{custom_iso_file}' already exists.")
            return

        # Prompt the user for the sudo password
        sudo_password = provide_pass()

        # Construct the command with sudo
        cmd = f"sudo -S {custom_iso_script_path}"
        cmd_args = shlex.split(cmd)

        # Run the command, providing the sudo password as input
        subprocess.run(cmd_args, input=sudo_password, check=True, text=True)

        print("Create.py: Custom ISO creation script executed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Create.py: Error during custom ISO creation: {e}")


def create_sub_vm():
    # Specify the path to your shell scripts
    create_script_path = "./create_sub_vm.sh"

    sub_vm_name = "SubVM"
    # Run the custom ISO creation script
    create_custom_iso()

    # Run the shell script to create the sub-VM
    # try:
    #     cmd = f"{create_script_path} {sub_vm_name}"
    #     subprocess.run(shlex.split(cmd), check=True)
    #     print("Sub-VM creation script executed successfully.")
    #
    #     while True:
    #         vm_info = subprocess.run(
    #             ["VBoxManage", "showvminfo", sub_vm_name],
    #             stdout=subprocess.PIPE,
    #             stderr=subprocess.PIPE,
    #             text=True,
    #         )
    #
    #         if "State: running" in vm_info.stdout:
    #             print("Sub-VM is now running.")
    #             break
    #
    #         time.sleep(5)  # Wait for 5 seconds before checking again
    #
    # except subprocess.CalledProcessError as e:
    #     print(f"Error during sub-VM creation: {e}")


if __name__ == "__main__":
    create_sub_vm()
