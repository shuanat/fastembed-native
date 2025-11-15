#!/usr/bin/env python3
"""
Download ONNX model from HuggingFace Hub for FastEmbed

Purpose:
    Downloads the nomic-embed-text-v1 ONNX model from HuggingFace Hub
    and places it in the models/ directory for use with FastEmbed.

Usage:
    python scripts/download_model.py

Requirements:
    - Python 3.6+
    - huggingface-hub package (installed automatically in virtual environment)

Platform Support:
    - Windows
    - Linux
    - macOS

Exit Codes:
    0 - Success
    1 - Error (missing dependency, download failure, etc.)

Author:
    FastEmbed Team
"""

import sys
import os
import argparse
from pathlib import Path
from typing import Optional

# Log levels
LOG_INFO = "INFO"
LOG_WARN = "WARN"
LOG_ERROR = "ERROR"

def log(level: str, message: str, quiet: bool = False):
    """Print log message with level prefix"""
    if not quiet:
        print(f"[{level}] {message}", flush=True)

def main() -> int:
    """Main function to download ONNX model"""
    parser = argparse.ArgumentParser(
        description="Download ONNX model from HuggingFace Hub for FastEmbed"
    )
    parser.add_argument(
        '--quiet', '-q',
        action='store_true',
        help='Suppress non-error output'
    )
    parser.add_argument(
        '--force', '-f',
        action='store_true',
        help='Force re-download even if model already exists'
    )
    args = parser.parse_args()
    
    repo_id = "nomic-ai/nomic-embed-text-v1"
    filename = "onnx/model.onnx"
    local_dir = "models/nomic-embed-text"
    target_path = Path("models/nomic-embed-text.onnx")
    
    # Check if model already exists
    if target_path.exists() and not args.force:
        log(LOG_INFO, f"Model already exists at {target_path}", args.quiet)
        log(LOG_INFO, "Use --force to re-download", args.quiet)
        return 0
    
    # Check for huggingface_hub
    try:
        from huggingface_hub import hf_hub_download
    except ImportError:
        log(LOG_ERROR, "huggingface_hub package not installed")
        log(LOG_ERROR, "Please run: pip install huggingface-hub")
        log(LOG_ERROR, "Or use virtual environment: python -m venv .venv && .venv\\Scripts\\activate")
        return 1
    
    # Validate inputs
    if not repo_id or not filename:
        log(LOG_ERROR, "Invalid configuration: repo_id or filename is empty")
        return 1
    
    try:
        log(LOG_INFO, f"Downloading model from {repo_id}...", args.quiet)
        log(LOG_INFO, f"Target: {target_path}", args.quiet)
        
        # Download model
        model_path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=local_dir
        )
        
        if not model_path or not os.path.exists(model_path):
            log(LOG_ERROR, f"Downloaded file not found: {model_path}")
            return 1
        
        # Create target directory
        target_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Copy to target location
        import shutil
        if args.force and target_path.exists():
            target_path.unlink()
        
        shutil.copy2(model_path, target_path)
        
        # Verify copy
        if not target_path.exists():
            log(LOG_ERROR, f"Failed to copy model to {target_path}")
            return 1
        
        file_size_mb = target_path.stat().st_size / (1024 * 1024)
        log(LOG_INFO, f"✅ Model downloaded successfully to {target_path}", args.quiet)
        log(LOG_INFO, f"   Size: {file_size_mb:.2f} MB", args.quiet)
        return 0
        
    except KeyboardInterrupt:
        log(LOG_WARN, "Download interrupted by user")
        return 130  # Standard exit code for Ctrl+C
    except Exception as e:
        log(LOG_ERROR, f"Failed to download model: {e}")
        log(LOG_ERROR, f"   Repository: {repo_id}")
        log(LOG_ERROR, f"   File: {filename}")
        log(LOG_ERROR, "   Suggestions:")
        log(LOG_ERROR, "     1. Check your internet connection")
        log(LOG_ERROR, "     2. Verify the model repository exists on HuggingFace Hub")
        log(LOG_ERROR, "     3. Try again later if HuggingFace Hub is experiencing issues")
        return 1

if __name__ == "__main__":
    sys.exit(main())

