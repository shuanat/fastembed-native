#!/usr/bin/env python3
"""Download ONNX model from HuggingFace Hub"""

import sys
import os
from pathlib import Path

try:
    from huggingface_hub import hf_hub_download
except ImportError:
    print("❌ huggingface_hub not installed. Please run: pip install huggingface-hub")
    sys.exit(1)

def main():
    repo_id = "nomic-ai/nomic-embed-text-v1"
    filename = "onnx/model.onnx"
    local_dir = "models/nomic-embed-text"
    target_path = "models/nomic-embed-text.onnx"
    
    try:
        # Download model
        model_path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=local_dir
        )
        
        # Copy to target location
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        import shutil
        shutil.copy2(model_path, target_path)
        
        print(f"✅ Model downloaded to {target_path}")
        return 0
    except Exception as e:
        print(f"❌ Failed to download model: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

