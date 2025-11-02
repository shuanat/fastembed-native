"""
FastEmbed Python pybind11 Benchmark

Measures performance of embedding generation and vector operations
"""

import time
import numpy as np
from fastembed_native import FastEmbedNative

ITERATIONS = 1000
DIMENSION = 768

print('FastEmbed Python pybind11 Benchmark')
print('====================================\n')
print(f'Iterations: {ITERATIONS}')
print(f'Dimension: {DIMENSION}\n')

client = FastEmbedNative(DIMENSION)

# Test text samples
texts = [
    "machine learning",
    "artificial intelligence and deep learning",
    "natural language processing with transformers",
    "computer vision and image recognition systems",
    "The quick brown fox jumps over the lazy dog and runs through the forest"
]

def benchmark(name, fn, iterations=ITERATIONS):
    """Run benchmark and print results"""
    # Warmup
    for _ in range(100):
        fn()
    
    # Measure
    start = time.perf_counter_ns()
    for _ in range(iterations):
        fn()
    end = time.perf_counter_ns()
    
    total_ns = end - start
    avg_ns = total_ns / iterations
    avg_ms = avg_ns / 1_000_000
    throughput = 1_000_000_000 / avg_ns
    
    print(f'{name}:')
    print(f'  Avg time: {avg_ms:.3f} ms')
    print(f'  Throughput: {int(throughput):,} ops/sec')
    print()
    
    return {'avg_ms': avg_ms, 'throughput': throughput}

# Benchmark: Embedding Generation (various text lengths)
print('--- Embedding Generation ---\n')

emb_results = {}
for idx, text in enumerate(texts):
    result = benchmark(
        f'Text {idx + 1} ({len(text)} chars)',
        lambda t=text: client.generate_embedding(t)
    )
    emb_results[f'text{idx + 1}'] = result

# Pre-generate embeddings for vector operations
emb1 = client.generate_embedding(texts[0])
emb2 = client.generate_embedding(texts[1])

print('--- Vector Operations ---\n')

# Benchmark: Cosine Similarity
cosine_result = benchmark(
    'Cosine Similarity',
    lambda: client.cosine_similarity(emb1, emb2)
)

# Benchmark: Dot Product
dot_result = benchmark(
    'Dot Product',
    lambda: client.dot_product(emb1, emb2)
)

# Benchmark: Vector Norm
norm_result = benchmark(
    'Vector Norm',
    lambda: client.vector_norm(emb1)
)

# Benchmark: Normalize Vector
normalize_result = benchmark(
    'Normalize Vector',
    lambda: client.normalize_vector(emb1)
)

# Benchmark: Add Vectors
add_result = benchmark(
    'Add Vectors',
    lambda: client.add_vectors(emb1, emb2)
)

# Summary
print('====================================')
print('Summary:')
print(f'  Embedding (avg): {emb_results["text1"]["avg_ms"]:.3f} ms')
print(f'  Cosine Similarity: {cosine_result["avg_ms"]:.3f} ms')
print(f'  Dot Product: {dot_result["avg_ms"]:.3f} ms')
print(f'  Vector Norm: {norm_result["avg_ms"]:.3f} ms')
print('====================================')

