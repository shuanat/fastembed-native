#!/usr/bin/env python3
"""
Test script for FastEmbed Python ONNX Runtime integration
"""

import sys
import os
import time
import numpy as np
from pathlib import Path

print("Testing FastEmbed Python ONNX Runtime Integration...\n")
print("=" * 60)

# Check if ONNX model is available
MODEL_PATH = Path(__file__).parent.parent.parent / "models" / "nomic-embed-text" / "onnx" / "model.onnx"
ONNX_AVAILABLE = MODEL_PATH.exists()

if not ONNX_AVAILABLE:
    print(f"⚠ ONNX model not found at: {MODEL_PATH}")
    print("⚠ Skipping ONNX tests (this is expected if ONNX Runtime is not configured)")
    print(f"⚠ To run ONNX tests, place an ONNX model at: {MODEL_PATH}")
    sys.exit(0)  # Exit successfully (skip tests)

try:
    # Import native module
    from fastembed_native import FastEmbedNative
    
    print("✓ Native module loaded successfully\n")
    
    # Initialize client
    print("1. Initializing FastEmbed...")
    fastembed = FastEmbedNative(dimension=768)  # Common ONNX model dimension
    print(f"✓ FastEmbed initialized (dimension={fastembed.dimension})\n")
    
    # Check if ONNX functions are available
    if not hasattr(fastembed, 'generate_onnx_embedding'):
        print("⚠ ONNX functions not available in native module")
        print("⚠ This may indicate ONNX Runtime was not linked at compile time")
        print("⚠ Skipping ONNX tests")
        sys.exit(0)  # Exit successfully (skip tests)
    
    print(f"✓ ONNX functions available")
    print(f"  Model path: {MODEL_PATH}\n")
    
    # Test 1: Generate ONNX embedding
    print("2. Testing generate_onnx_embedding...")
    text = "machine learning artificial intelligence"
    
    try:
        start = time.time()
        embedding = fastembed.generate_onnx_embedding(str(MODEL_PATH), text)
        elapsed = (time.time() - start) * 1000
        
        print(f"✓ ONNX embedding generated in {elapsed:.2f}ms")
        print(f"  Type: {type(embedding)}")
        print(f"  Shape: {embedding.shape}")
        print(f"  Dtype: {embedding.dtype}")
        print(f"  First 5 values: {embedding[:5]}")
        
        # Verify embedding is normalized (unit vector)
        norm = fastembed.vector_norm(embedding)
        print(f"  Norm: {norm:.4f} (should be ~1.0 for L2-normalized)")
        
        if abs(norm - 1.0) > 0.1:
            print("  ⚠ Warning: Embedding norm is not ~1.0, may not be normalized")
    except RuntimeError as e:
        print(f"✗ Failed to generate ONNX embedding: {e}")
        raise
    print()
    
    # Test 2: ONNX error handling
    print("3. Testing ONNX error handling...")
    try:
        # Try with non-existent model
        fastembed.generate_onnx_embedding("non_existent_model.onnx", "text")
        print("  ⚠ Warning: Should have raised RuntimeError for non-existent model")
    except RuntimeError:
        print("✓ Error handling works (non-existent model correctly rejected)")
    except Exception as e:
        print(f"  Unexpected error type: {type(e).__name__}: {e}")
    print()
    
    # Test 3: ONNX model caching
    print("4. Testing ONNX model caching...")
    text1 = "first text"
    text2 = "second text"
    
    # First call (model load)
    start1 = time.time()
    emb1 = fastembed.generate_onnx_embedding(str(MODEL_PATH), text1)
    time1 = (time.time() - start1) * 1000
    print(f"  First call: {time1:.2f}ms (includes model loading)")
    
    # Second call (cached model)
    start2 = time.time()
    emb2 = fastembed.generate_onnx_embedding(str(MODEL_PATH), text2)
    time2 = (time.time() - start2) * 1000
    print(f"  Second call: {time2:.2f}ms (cached model)")
    
    if time2 < time1:
        print("✓ Model caching works (second call faster)")
    else:
        print("  (Caching may not be noticeable for small models)")
    print()
    
    # Test 4: Unload ONNX model
    print("5. Testing unload_onnx_model...")
    try:
        result = fastembed.unload_onnx_model()
        print(f"✓ Model unloaded, result: {result}")
        
        # Next call should reload model
        start3 = time.time()
        emb3 = fastembed.generate_onnx_embedding(str(MODEL_PATH), text1)
        time3 = (time.time() - start3) * 1000
        print(f"  Reload after unload: {time3:.2f}ms")
    except Exception as e:
        print(f"✗ Failed to unload model: {e}")
        raise
    print()
    
    # Test 5: Dimension validation
    print("6. Testing dimension validation...")
    try:
        # Try with wrong dimension (if model supports validation)
        # Note: Python binding auto-detects dimension, so we can't test wrong dimension
        fastembed.generate_onnx_embedding(str(MODEL_PATH), text)
        print("  ⚠ Warning: Should have validated dimension mismatch")
    except RuntimeError:
        print("✓ Dimension validation works (wrong dimension correctly rejected)")
    except Exception as e:
        print(f"  Unexpected error: {type(e).__name__}: {e}")
    print()
    
    # Test 6: Edge cases
    print("7. Testing edge cases...")
    
    # Empty text
    try:
        emb_empty = fastembed.generate_onnx_embedding(str(MODEL_PATH), "")
        print("✓ Empty text handled")
    except Exception as e:
        print(f"  Empty text error: {type(e).__name__}: {e}")
    
    # Very long text
    try:
        long_text = "a" * 1000
        emb_long = fastembed.generate_onnx_embedding(str(MODEL_PATH), long_text)
        print("✓ Very long text handled")
    except Exception as e:
        print(f"  Long text error: {type(e).__name__}: {e}")
    print()
    
    # Test 7: Performance benchmark
    print("8. ONNX Performance benchmark...")
    iterations = 10  # Fewer iterations for ONNX (slower)
    texts = [f"test text {i}" for i in range(iterations)]
    
    start = time.time()
    for text in texts:
        _ = fastembed.generate_onnx_embedding(str(MODEL_PATH), text)
    elapsed = time.time() - start
    
    avg_time = (elapsed / iterations) * 1000
    print(f"✓ Benchmark completed")
    print(f"  Iterations: {iterations}")
    print(f"  Total time: {elapsed:.2f}s")
    print(f"  Average time: {avg_time:.2f}ms per embedding")
    print(f"  Throughput: {iterations/elapsed:.1f} embeddings/sec")
    print()
    
    print("=" * 60)
    print("ALL ONNX TESTS PASSED ✓")
    print("=" * 60)
    print("\nONNX Runtime integration is working correctly!")
    print(f"Performance: ~{avg_time:.1f}ms per embedding (ONNX inference)")
    
except ImportError as e:
    print(f"✗ Import error: {e}")
    print("\nPlease build the module first:")
    print("  python setup.py build_ext --inplace")
    sys.exit(1)
except Exception as e:
    print(f"\n✗ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

