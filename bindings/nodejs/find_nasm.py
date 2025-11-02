#!/usr/bin/env python3
"""Helper script to find NASM executable on Windows"""
import os
import shutil
import sys

def find_nasm():
    # Try PATH first
    nasm = shutil.which("nasm")
    if nasm and os.path.exists(nasm):
        return os.path.normpath(nasm)
    
    # Try common Windows locations
    common_paths = [
        os.path.join(os.path.expanduser("~"), "AppData", "Local", "bin", "NASM", "nasm.exe"),
        "C:\\Program Files\\NASM\\nasm.exe",
        "C:\\Program Files (x86)\\NASM\\nasm.exe",
    ]
    
    for path in common_paths:
        norm_path = os.path.normpath(path)
        if os.path.exists(norm_path):
            return norm_path
    
    return "nasm"  # Fallback, will fail but give clearer error

if __name__ == "__main__":
    nasm_path = find_nasm()
    # Return with quotes if path contains spaces
    if " " in nasm_path:
        print(f'"{nasm_path}"')
    else:
        print(nasm_path)

