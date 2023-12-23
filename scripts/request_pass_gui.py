import tkinter as tk
from tkinter import simpledialog
import sys

def provide_pass():
    try:
        root = tk.Tk()
        root.withdraw()  # Hide the root window

        # Create the password dialog
        password = simpledialog.askstring("Password", "Enter your sudo password:", show='*')

        root.destroy()

        if not password:
            print("No password entered. Exiting.")
            return None

        return password
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

