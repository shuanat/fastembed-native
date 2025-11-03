"""
FastEmbed Python ONNX Benchmark

Compares hash-based vs ONNX embeddings for speed, memory, and quality.
Tests with realistic text sizes (100, 500, 2000 chars) and batch processing.
"""

import time
import json
import sys
import os
from pathlib import Path

try:
    import psutil
    import numpy as np
    from fastembed_native import FastEmbedNative, generate_embedding, generate_onnx_embedding, cosine_similarity
except ImportError as e:
    print(f"Error importing required modules: {e}")
    print("Please install: pip install psutil numpy")
    sys.exit(1)

# Configuration
DIMENSION = 768  # ONNX model only supports 768D
ITERATIONS_SINGLE = 100
ITERATIONS_BATCH = 10
BATCH_SIZES = [1, 10, 100]

# ONNX model path (relative to this script)
SCRIPT_DIR = Path(__file__).parent
MODEL_PATH = str(SCRIPT_DIR.parent.parent / "models" / "nomic-embed-text.onnx")

# Realistic text samples
TEXT_SAMPLES = {
    "short": "machine learning algorithms and neural networks for artificial intelligence applications in computer science",
    "medium": "Machine learning is a subset of artificial intelligence that focuses on developing algorithms capable of learning from data without being explicitly programmed. These algorithms can identify patterns, make predictions, and improve their performance over time through experience. Neural networks, a key component of modern machine learning, are inspired by the structure of the human brain and consist of interconnected nodes that process information in layers.",
    "long": """Machine learning represents a revolutionary approach to artificial intelligence that has transformed numerous industries and applications. At its core, machine learning involves the creation of algorithms that can learn from data, identify patterns, and make decisions with minimal human intervention. This field encompasses various techniques, including supervised learning where models are trained on labeled datasets, unsupervised learning that discovers hidden patterns in unlabeled data, and reinforcement learning where agents learn through interaction with their environment.

Neural networks, particularly deep neural networks, have become the cornerstone of modern machine learning. These sophisticated systems consist of multiple layers of interconnected nodes, or neurons, that process information in a hierarchical manner. The depth and complexity of these networks enable them to capture intricate relationships in data, making them exceptionally powerful for tasks such as image recognition, natural language processing, and predictive analytics.

The applications of machine learning are vast and continue to expand. In healthcare, ML models assist in disease diagnosis and drug discovery. In finance, they power fraud detection systems and algorithmic trading. In transportation, they enable autonomous vehicles to navigate complex environments. As the field evolves, the integration of machine learning into everyday technology becomes increasingly seamless, promising a future where intelligent systems enhance human capabilities in unprecedented ways."""
}

def get_memory_usage():
    """Get current memory usage in MB"""
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / 1024 / 1024

def benchmark_function(name, fn, iterations, warmup=10):
    """Benchmark a function and return metrics"""
    # Warmup
    for _ in range(warmup):
        fn()
    
    # Measure time
    start = time.perf_counter_ns()
    start_mem = get_memory_usage()
    
    results = []
    for _ in range(iterations):
        result = fn()
        results.append(result)
    
    end_mem = get_memory_usage()
    end = time.perf_counter_ns()
    
    total_ns = end - start
    avg_ns = total_ns / iterations
    avg_ms = avg_ns / 1_000_000
    throughput = 1_000_000_000 / avg_ns
    peak_mem = max(get_memory_usage() for _ in range(5))  # Check peak over several measurements
    mem_delta = end_mem - start_mem
    
    return {
        "name": name,
        "avg_ms": avg_ms,
        "throughput": throughput,
        "start_mem_mb": start_mem,
        "end_mem_mb": end_mem,
        "peak_mem_mb": peak_mem,
        "mem_delta_mb": mem_delta,
        "iterations": iterations
    }

def compare_quality(text, hash_emb, onnx_emb):
    """Compare quality by computing cosine similarity between hash and ONNX embeddings"""
    similarity = cosine_similarity(hash_emb, onnx_emb)
    return similarity

def main():
    print("FastEmbed Python ONNX Benchmark")
    print("=" * 50)
    print(f"Dimension: {DIMENSION} (ONNX model limitation)")
    print(f"Model path: {MODEL_PATH}")
    print(f"Model exists: {os.path.exists(MODEL_PATH)}\n")
    
    if not os.path.exists(MODEL_PATH):
        print(f"ERROR: ONNX model not found at {MODEL_PATH}")
        print("Please ensure the model is available.")
        sys.exit(1)
    
    client = FastEmbedNative(DIMENSION)
    results = {
        "dimension": DIMENSION,
        "timestamp": time.time(),
        "hash_based": {},
        "onnx_based": {},
        "quality_comparison": {},
        "batch_performance": {}
    }
    
    # Single embedding benchmarks (speed + memory)
    print("--- Single Embedding Generation (Speed + Memory) ---\n")
    
    for text_type, text in TEXT_SAMPLES.items():
        print(f"\nText type: {text_type} ({len(text)} chars)")
        print("-" * 50)
        
        # Hash-based embedding
        print("Hash-based:")
        hash_result = benchmark_function(
            f"hash_{text_type}",
            lambda t=text: client.generate_embedding(t),
            ITERATIONS_SINGLE
        )
        hash_emb = client.generate_embedding(text)
        print(f"  Avg time: {hash_result['avg_ms']:.3f} ms")
        print(f"  Throughput: {int(hash_result['throughput']):,} ops/sec")
        print(f"  Memory delta: {hash_result['mem_delta_mb']:.2f} MB")
        results["hash_based"][text_type] = hash_result
        
        # ONNX embedding
        print("\nONNX-based:")
        onnx_result = benchmark_function(
            f"onnx_{text_type}",
            lambda t=text: generate_onnx_embedding(MODEL_PATH, t, DIMENSION),
            ITERATIONS_SINGLE
        )
        onnx_emb = generate_onnx_embedding(MODEL_PATH, text, DIMENSION)
        print(f"  Avg time: {onnx_result['avg_ms']:.3f} ms")
        print(f"  Throughput: {int(onnx_result['throughput']):,} ops/sec")
        print(f"  Memory delta: {onnx_result['mem_delta_mb']:.2f} MB")
        results["onnx_based"][text_type] = onnx_result
        
        # Quality comparison
        quality = compare_quality(text, hash_emb, onnx_emb)
        print(f"\nQuality (hash vs ONNX cosine similarity): {quality:.4f}")
        results["quality_comparison"][text_type] = {
            "cosine_similarity": float(quality),
            "text_length": len(text)
        }
        
        # Speedup ratio (how many times hash is faster than ONNX)
        speedup = onnx_result['avg_ms'] / hash_result['avg_ms'] if hash_result['avg_ms'] > 0 else 0
        print(f"\nSpeed ratio (hash/onnx): {speedup:.2f}x")
        if speedup > 1:
            print(f"  Hash-based is {speedup:.2f}x faster")
        elif speedup < 1 and speedup > 0:
            print(f"  ONNX is {1/speedup:.2f}x faster")
        else:
            print(f"  Unable to calculate speed ratio")
    
    # Batch processing benchmarks
    print("\n\n--- Batch Processing ---\n")
    
    text_list = list(TEXT_SAMPLES.values())
    
    for batch_size in BATCH_SIZES:
        print(f"\nBatch size: {batch_size}")
        print("-" * 50)
        
        # Hash-based batch
        print("Hash-based batch:")
        hash_batch_result = benchmark_function(
            f"hash_batch_{batch_size}",
            lambda: [client.generate_embedding(text_list[i % len(text_list)]) for i in range(batch_size)],
            ITERATIONS_BATCH
        )
        print(f"  Avg time per batch: {hash_batch_result['avg_ms']:.3f} ms")
        print(f"  Time per embedding: {hash_batch_result['avg_ms']/batch_size:.3f} ms")
        hash_throughput = int(1000.0 / (hash_batch_result['avg_ms'] / batch_size))
        print(f"  Throughput: {hash_throughput:,} embeddings/sec")
        
        # ONNX batch
        print("\nONNX-based batch:")
        onnx_batch_result = benchmark_function(
            f"onnx_batch_{batch_size}",
            lambda: [generate_onnx_embedding(MODEL_PATH, text_list[i % len(text_list)], DIMENSION) for i in range(batch_size)],
            ITERATIONS_BATCH
        )
        print(f"  Avg time per batch: {onnx_batch_result['avg_ms']:.3f} ms")
        print(f"  Time per embedding: {onnx_batch_result['avg_ms']/batch_size:.3f} ms")
        onnx_throughput = int(1000.0 / (onnx_batch_result['avg_ms'] / batch_size))
        print(f"  Throughput: {onnx_throughput:,} embeddings/sec")
        
        results["batch_performance"][f"batch_{batch_size}"] = {
            "hash_based": hash_batch_result,
            "onnx_based": onnx_batch_result
        }
    
    # Save results to JSON
    output_file = SCRIPT_DIR / "benchmark_onnx_results.json"
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n\nResults saved to: {output_file}")
    print("=" * 50)
    print("Benchmark completed!")

if __name__ == "__main__":
    main()

