#!/usr/bin/env python3
"""
Test script for FastEmbed Python native module
"""

import sys
import time
import numpy as np

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
    
    print("=" * 60)
    print("ALL TESTS PASSED ✓")
    print("=" * 60)
    print("\nFastEmbed Python native module is working correctly!")
    print(f"Performance: ~{avg_time:.1f}ms per embedding (native speed)")
    
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

