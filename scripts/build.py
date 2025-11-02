#!/usr/bin/env python3
"""Build script for FastEmbed - cross-platform"""

import sys
import os
import subprocess
import platform
from pathlib import Path


def convert_to_wsl_path(windows_path):
    """Convert Windows path to WSL path"""
    if platform.system() != "Windows":
        return windows_path
    
    try:
        result = subprocess.run(
            ["wsl", "wslpath", "-a", windows_path],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except Exception:
        # Fallback: manual conversion
        return windows_path.replace("\\", "/").replace("C:", "/mnt/c").replace("G:", "/mnt/g")


def has_wsl():
    """Check if WSL is available"""
    if platform.system() != "Windows":
        return False
    try:
        subprocess.run(["wsl", "--version"], capture_output=True, check=True)
        return True
    except Exception:
        return False


def run_make(target="all"):
    """Run make command"""
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent
    
    print("FastEmbed Build Script")
    print("======================")
    print()
    
    if platform.system() == "Windows":
        if has_wsl():
            print("Using WSL for building...", flush=True)
            current_path = str(project_dir.resolve())
            wsl_path = convert_to_wsl_path(current_path)
            
            if target == "clean":
                print("Cleaning...", flush=True)
                cmd = f"cd '{wsl_path}' && make clean"
            else:
                print(f"Building target: {target}...", flush=True)
                cmd = f"cd '{wsl_path}' && make {target}"
            
            result = subprocess.run(["wsl", "bash", "-c", cmd])
            
            if result.returncode != 0:
                print("Build failed!", flush=True)
                return 1
            
            print("Build completed successfully!", flush=True)
            return 0
        else:
            print("WSL not found. Please use one of the following:", flush=True)
            print()
            print("Option 1: Install WSL", flush=True)
            print("  wsl --install", flush=True)
            print()
            print("Option 2: Use MSYS2/MinGW", flush=True)
            print("  # In MSYS2 terminal:", flush=True)
            print(f"  make {target}", flush=True)
            return 1
    else:
        # Linux/macOS: run make directly
        os.chdir(project_dir)
        if target == "clean":
            print("Cleaning...", flush=True)
            cmd = ["make", "clean"]
        else:
            print(f"Building target: {target}...", flush=True)
            cmd = ["make", target]
        
        result = subprocess.run(cmd)
        return result.returncode


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    sys.exit(run_make(target))


if __name__ == "__main__":
    main()

