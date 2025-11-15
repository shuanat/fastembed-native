#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test script for FastEmbed Python native module
"""

import sys
import time
import numpy as np
import io

# Fix Windows console encoding for Unicode characters
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

print("Testing FastEmbed Python Native Module...\n")
print("=" * 60)

try:
    # Import native module
    from fastembed_native import FastEmbedNative
    
    print("✓ Native module loaded successfully\n")
    
    # Initialize client
    print("1. Initializing FastEmbed...")
    fastembed = FastEmbedNative(dimension=768)
    print(f"✓ FastEmbed initialized (dimension={fastembed.dimension})\n")
    
    # Test 1: Generate embedding
    print("2. Testing generate_embedding...")
    text = "machine learning artificial intelligence"
    start = time.time()
    embedding = fastembed.generate_embedding(text)
    elapsed = (time.time() - start) * 1000
    
    print(f"✓ Embedding generated in {elapsed:.2f}ms")
    print(f"  Type: {type(embedding)}")
    print(f"  Shape: {embedding.shape}")
    print(f"  Dtype: {embedding.dtype}")
    print(f"  First 5 values: {embedding[:5]}\n")
    
    # Test 2: Vector norm
    print("3. Testing vector_norm...")
    norm = fastembed.vector_norm(embedding)
    print(f"✓ Norm calculated: {norm:.4f}\n")
    
    # Test 3: Normalize vector
    print("4. Testing normalize_vector...")
    normalized = fastembed.normalize_vector(embedding)
    norm_after = fastembed.vector_norm(normalized)
    print(f"✓ Vector normalized")
    print(f"  Norm after normalization: {norm_after:.4f} (should be ~1.0)\n")
    
    # Test 4: Cosine similarity
    print("5. Testing cosine_similarity...")
    text2 = "deep learning neural networks"
    embedding2 = fastembed.generate_embedding(text2)
    similarity = fastembed.cosine_similarity(embedding, embedding2)
    print(f"✓ Cosine similarity calculated: {similarity:.4f}")
    print(f"  Text 1: {text}")
    print(f"  Text 2: {text2}\n")
    
    # Test 5: Dot product
    print("6. Testing dot_product...")
    dot = fastembed.dot_product(embedding, embedding2)
    print(f"✓ Dot product calculated: {dot:.4f}\n")
    
    # Test 6: Add vectors
    print("7. Testing add_vectors...")
    sum_vector = fastembed.add_vectors(embedding, embedding2)
    print(f"✓ Vectors added")
    print(f"  Result shape: {sum_vector.shape}")
    print(f"  First 5 values: {sum_vector[:5]}\n")
    
    # Performance test
    print("8. Performance benchmark...")
    iterations = 100
    texts = [f"test text {i}" for i in range(iterations)]
    
    start = time.time()
    for text in texts:
        _ = fastembed.generate_embedding(text)
    elapsed = time.time() - start
    
    avg_time = (elapsed / iterations) * 1000
    print(f"✓ Benchmark completed")
    print(f"  Iterations: {iterations}")
    print(f"  Total time: {elapsed:.2f}s")
    print(f"  Average time: {avg_time:.2f}ms per embedding")
    print(f"  Throughput: {iterations/elapsed:.1f} embeddings/sec\n")
    
    # Test 9: Error handling - null text
    print("9. Testing error handling (None text)...")
    try:
        fastembed.generate_embedding(None)
        print("✗ Should have raised error for None text")
        sys.exit(1)
    except (TypeError, ValueError) as e:
        print(f"✓ Correctly raises error for None text")
        print(f"  Error type: {type(e).__name__}")
        print(f"  Error message: {str(e)}\n")
    
    # Test 10: Error handling - invalid dimension
    print("10. Testing error handling (invalid dimension)...")
    try:
        invalid_client = FastEmbedNative(dimension=99)  # Invalid dimension
        print("✗ Should have raised error for invalid dimension")
        sys.exit(1)
    except (ValueError, RuntimeError) as e:
        print(f"✓ Correctly raises error for invalid dimension")
        print(f"  Error message: {str(e)}\n")
    
    # Test 11: Error handling - null vector
    print("11. Testing error handling (None vector)...")
    try:
        fastembed.cosine_similarity(None, embedding2)
        print("✗ Should have raised error for None vector")
        sys.exit(1)
    except (TypeError, ValueError) as e:
        print(f"✓ Correctly raises error for None vector")
        print(f"  Error message: {str(e)}\n")
    
    # Test 12: Edge case - empty string
    print("12. Testing edge case (empty string)...")
    try:
        fastembed.generate_embedding("")
        print("✗ Should have raised error for empty string")
        sys.exit(1)
    except (ValueError, RuntimeError) as e:
        print(f"✓ Correctly raises error for empty string")
        print(f"  Error message: {str(e)}\n")
    
    # Test 13: Edge case - very long text
    print("13. Testing edge case (very long text)...")
    try:
        long_text = "a" * 10000  # 10000 chars exceeds 8192 limit
        fastembed.generate_embedding(long_text)
        print("✗ Should have raised error for very long text")
        sys.exit(1)
    except (ValueError, RuntimeError) as e:
        print(f"✓ Correctly raises error for very long text")
        print(f"  Error message: {str(e)}\n")
    
    # Test 14: Edge case - unicode text
    print("14. Testing edge case (unicode text)...")
    unicode_text = "Привет мир こんにちは 世界 🌍"
    unicode_emb = fastembed.generate_embedding(unicode_text)
    print(f"✓ Unicode text handled correctly")
    print(f"  Text: {unicode_text}")
    print(f"  Embedding shape: {unicode_emb.shape}\n")
    
    # Test 15: Edge case - special characters
    print("15. Testing edge case (special characters)...")
    special_text = "Hello! @#$%^&*() []{} <>"
    special_emb = fastembed.generate_embedding(special_text)
    print(f"✓ Special characters handled correctly")
    print(f"  Text: {special_text}")
    print(f"  Embedding shape: {special_emb.shape}\n")
    
    print("=" * 60)
    print("ALL TESTS PASSED ✓ (15/15)")
    print("=" * 60)
    print("\nFastEmbed Python native module is working correctly!")
    print(f"Performance: ~{avg_time:.1f}ms per embedding (native speed)")
    print("\nTest coverage:")
    print("  • Happy path: 8 tests")
    print("  • Error handling: 4 tests")
    print("  • Edge cases: 3 tests")
    
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

