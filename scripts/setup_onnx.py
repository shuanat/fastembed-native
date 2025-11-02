#!/usr/bin/env python3
"""Download and setup ONNX Runtime for FastEmbed"""

import sys
import os
import platform
import tempfile
import shutil
import tarfile
import urllib.request
from pathlib import Path


ONNX_VERSION = "1.23.2"


def get_platform_info():
    """Detect platform and architecture"""
    os_name = platform.system()
    arch = platform.machine()
    
    platform_map = {
        ("Linux", "x86_64"): "linux-x64",
        ("Linux", "aarch64"): "linux-aarch64",
        ("Darwin", "x86_64"): "osx-x64",
        ("Darwin", "arm64"): "osx-arm64",
    }
    
    key = (os_name, arch)
    if key not in platform_map:
        print(f"❌ Unsupported platform: {os_name} {arch}")
        print("   Please download ONNX Runtime manually from:")
        print("   https://github.com/microsoft/onnxruntime/releases")
        sys.exit(1)
    
    return platform_map[key]


def download_file(url, dest_path):
    """Download file with progress"""
    def show_progress(block_num, block_size, total_size):
        if total_size > 0:
            percent = min(100, (block_num * block_size * 100) // total_size)
            size_mb = total_size / (1024 * 1024)
            downloaded_mb = (block_num * block_size) / (1024 * 1024)
            print(f"\r📥 Downloading: {downloaded_mb:.1f}/{size_mb:.1f} MB ({percent}%)", end="", flush=True)
    
    try:
        urllib.request.urlretrieve(url, dest_path, reporthook=show_progress)
        print()  # New line after progress
        return True
    except Exception as e:
        print(f"\n❌ Download failed: {e}")
        return False


def main():
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent
    onnx_dir = project_dir / "onnxruntime"
    onnx_arch = get_platform_info()
    onnx_url = f"https://github.com/microsoft/onnxruntime/releases/download/v{ONNX_VERSION}/onnxruntime-{onnx_arch}-{ONNX_VERSION}.tgz"
    
    print("Setting up ONNX Runtime for FastEmbed...")
    print(f"Platform: {platform.system()} {platform.machine()}")
    print(f"Version: {ONNX_VERSION}")
    print(f"Target directory: {onnx_dir}")
    print(f"URL: {onnx_url}")
    
    # Check if already installed
    header_file = onnx_dir / "include" / "onnxruntime_c_api.h"
    if header_file.exists():
        print(f"\n✅ ONNX Runtime already installed at {onnx_dir}")
        print(f"   Include: {onnx_dir / 'include'}")
        if (onnx_dir / "lib").exists():
            print(f"   Library: {onnx_dir / 'lib'}")
        return 0
    
    # Create directory
    onnx_dir.mkdir(parents=True, exist_ok=True)
    
    # Download
    print(f"\n📥 Downloading ONNX Runtime {ONNX_VERSION} for {onnx_arch}...")
    with tempfile.TemporaryDirectory() as temp_dir:
        archive_path = Path(temp_dir) / f"onnxruntime-{onnx_arch}-{ONNX_VERSION}.tgz"
        
        if not download_file(onnx_url, str(archive_path)):
            print("\n❌ Failed to download ONNX Runtime")
            print(f"   URL: {onnx_url}")
            print("\n💡 Suggestions:")
            print("   1. Check your internet connection")
            print("   2. Visit https://github.com/microsoft/onnxruntime/releases")
            print(f"   3. Download manually and extract to {onnx_dir}")
            return 1
        
        # Extract
        print("📦 Extracting ONNX Runtime...")
        try:
            with tarfile.open(archive_path, "r:gz") as tar:
                # Find the root directory in archive
                members = tar.getmembers()
                root_dirs = {m.name.split("/")[0] for m in members if "/" in m.name}
                
                # Extract to temp directory first
                extract_dir = Path(temp_dir) / "extract"
                extract_dir.mkdir()
                tar.extractall(extract_dir)
                
                # Find onnxruntime directory
                onnx_extracted = None
                for root_dir in root_dirs:
                    candidate = extract_dir / root_dir
                    if (candidate / "include" / "onnxruntime_c_api.h").exists():
                        onnx_extracted = candidate
                        break
                
                if not onnx_extracted:
                    # Try to find files directly
                    header_candidates = list(extract_dir.rglob("onnxruntime_c_api.h"))
                    if header_candidates:
                        onnx_extracted = header_candidates[0].parent.parent
                
                if onnx_extracted and onnx_extracted.exists():
                    # Move files to target
                    for item in onnx_extracted.iterdir():
                        dest = onnx_dir / item.name
                        if item.is_dir():
                            if dest.exists():
                                shutil.rmtree(dest)
                            shutil.copytree(item, dest)
                        else:
                            shutil.copy2(item, dest)
                else:
                    print("⚠️ Unexpected archive structure, trying to copy files...")
                    # Fallback: copy important files
                    for pattern in ["**/onnxruntime_c_api.h", "**/libonnxruntime.so*", "**/onnxruntime.dll"]:
                        for file_path in extract_dir.rglob(pattern):
                            rel_path = file_path.relative_to(extract_dir)
                            dest_path = project_dir / rel_path
                            dest_path.parent.mkdir(parents=True, exist_ok=True)
                            if file_path.is_file():
                                shutil.copy2(file_path, dest_path)
        
        except Exception as e:
            print(f"❌ Failed to extract archive: {e}")
            return 1
    
    # Verify installation
    if header_file.exists():
        print("\n✅ ONNX Runtime installed successfully!")
        print(f"   Location: {onnx_dir}")
        print(f"   Include: {onnx_dir / 'include'}")
        if (onnx_dir / "lib").exists():
            print(f"   Library: {onnx_dir / 'lib'}")
        print("\nYou can now build FastEmbed with ONNX Runtime support:")
        print("   make all")
        return 0
    else:
        print("\n❌ Installation verification failed")
        print(f"   Expected header file not found: {header_file}")
        print("   Archive structure may have changed. Please download manually.")
        return 1


if __name__ == "__main__":
    sys.exit(main())

