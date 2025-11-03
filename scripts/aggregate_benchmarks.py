"""
Aggregate benchmark results from all language bindings
Generates comparison tables and markdown documentation
"""

import json
import os
from pathlib import Path
from typing import Dict, Any

# Paths to benchmark results
BENCHMARK_PATHS = {
    "python": Path(__file__).parent.parent / "bindings" / "python" / "benchmark_onnx_results.json",
    "nodejs": Path(__file__).parent.parent / "bindings" / "nodejs" / "benchmark_onnx_results.json",
    "java": Path(__file__).parent.parent / "bindings" / "java" / "benchmark_onnx_results.json",
    "csharp": Path(__file__).parent.parent / "bindings" / "csharp" / "benchmark_onnx_results.json"
}

def load_results(language: str) -> Dict[str, Any]:
    """Load benchmark results for a language"""
    path = BENCHMARK_PATHS[language]
    if not path.exists():
        print(f"Warning: {language} benchmark results not found at {path}")
        return None
    with open(path, 'r') as f:
        return json.load(f)

def generate_speed_comparison_table(results: Dict[str, Dict[str, Any]]) -> str:
    """Generate speed comparison table"""
    lines = ["## Speed Comparison (Hash vs ONNX)\n"]
    lines.append("| Language | Text Size | Hash (ms) | ONNX (ms) | Speedup |")
    lines.append("|----------|-----------|-----------|-----------|---------|")
    
    text_types = ["short", "medium", "long"]
    
    for lang, data in results.items():
        if data is None:
            continue
        hash_data = data.get("hash_based", {})
        onnx_data = data.get("onnx_based", {})
        
        for text_type in text_types:
            if text_type not in hash_data or text_type not in onnx_data:
                continue
            
            hash_ms = hash_data[text_type].get("avg_ms", 0)
            onnx_ms = onnx_data[text_type].get("avg_ms", 0)
            speedup = hash_ms / onnx_ms if onnx_ms > 0 else 0
            
            lines.append(f"| {lang.capitalize()} | {text_type} | {hash_ms:.3f} | {onnx_ms:.3f} | {speedup:.2f}x |")
    
    return "\n".join(lines)

def generate_memory_comparison_table(results: Dict[str, Dict[str, Any]]) -> str:
    """Generate memory comparison table"""
    lines = ["## Memory Usage Comparison (Hash vs ONNX)\n"]
    lines.append("| Language | Text Size | Hash (MB) | ONNX (MB) | Ratio |")
    lines.append("|----------|-----------|-----------|-----------|-------|")
    
    text_types = ["short", "medium", "long"]
    
    for lang, data in results.items():
        if data is None:
            continue
        hash_data = data.get("hash_based", {})
        onnx_data = data.get("onnx_based", {})
        
        for text_type in text_types:
            if text_type not in hash_data or text_type not in onnx_data:
                continue
            
            hash_mem = hash_data[text_type].get("mem_delta_mb", 0)
            onnx_mem = onnx_data[text_type].get("mem_delta_mb", 0)
            ratio = hash_mem / onnx_mem if onnx_mem > 0 else 0
            
            lines.append(f"| {lang.capitalize()} | {text_type} | {hash_mem:.2f} | {onnx_mem:.2f} | {ratio:.2f}x |")
    
    return "\n".join(lines)

def generate_quality_table(results: Dict[str, Dict[str, Any]]) -> str:
    """Generate quality comparison table"""
    lines = ["## Quality Comparison (Hash vs ONNX Cosine Similarity)\n"]
    lines.append("| Language | Text Size | Cosine Similarity |")
    lines.append("|----------|-----------|-------------------|")
    
    text_types = ["short", "medium", "long"]
    
    for lang, data in results.items():
        if data is None:
            continue
        quality_data = data.get("quality_comparison", {})
        
        for text_type in text_types:
            if text_type not in quality_data:
                continue
            
            similarity = quality_data[text_type].get("cosine_similarity", 0)
            lines.append(f"| {lang.capitalize()} | {text_type} | {similarity:.4f} |")
    
    return "\n".join(lines)

def generate_batch_performance_table(results: Dict[str, Dict[str, Any]]) -> str:
    """Generate batch performance table"""
    lines = ["## Batch Performance Comparison\n"]
    lines.append("| Language | Batch Size | Hash (emb/s) | ONNX (emb/s) | Ratio |")
    lines.append("|----------|------------|--------------|--------------|-------|")
    
    batch_sizes = ["batch_1", "batch_10", "batch_100"]
    
    for lang, data in results.items():
        if data is None:
            continue
        batch_data = data.get("batch_performance", {})
        
        for batch_size in batch_sizes:
            if batch_size not in batch_data:
                continue
            
            batch_info = batch_data[batch_size]
            hash_throughput = batch_info.get("hash_based", {}).get("throughput", 0)
            onnx_throughput = batch_info.get("onnx_based", {}).get("throughput", 0)
            
            # Extract batch size number
            size_num = batch_size.split("_")[1]
            hash_emb_per_sec = hash_throughput * int(size_num)
            onnx_emb_per_sec = onnx_throughput * int(size_num)
            ratio = hash_emb_per_sec / onnx_emb_per_sec if onnx_emb_per_sec > 0 else 0
            
            lines.append(f"| {lang.capitalize()} | {size_num} | {hash_emb_per_sec:,.0f} | {onnx_emb_per_sec:,.0f} | {ratio:.2f}x |")
    
    return "\n".join(lines)

def generate_summary(results: Dict[str, Dict[str, Any]]) -> str:
    """Generate summary section"""
    lines = ["## Summary\n"]
    
    available_langs = [lang for lang, data in results.items() if data is not None]
    lines.append(f"Benchmarks available for: {', '.join([l.capitalize() for l in available_langs])}\n")
    
    lines.append("### Key Findings:\n")
    lines.append("1. **Speed**: Hash-based embeddings are typically faster than ONNX embeddings")
    lines.append("2. **Memory**: ONNX embeddings require more memory due to model loading")
    lines.append("3. **Quality**: ONNX embeddings provide semantic understanding, hash-based are deterministic")
    lines.append("4. **Batch Processing**: Performance scales differently for hash vs ONNX\n")
    
    lines.append("### Recommendations:\n")
    lines.append("- Use **hash-based** embeddings for:")
    lines.append("  - Fast, deterministic embeddings")
    lines.append("  - Low memory usage")
    lines.append("  - Any dimension size\n")
    lines.append("- Use **ONNX** embeddings for:")
    lines.append("  - Semantic similarity search")
    lines.append("  - Quality over speed")
    lines.append("  - 768-dimensional embeddings only\n")
    
    return "\n".join(lines)

def main():
    """Main aggregation function"""
    print("Aggregating benchmark results...")
    
    # Load all results
    results = {}
    for lang in BENCHMARK_PATHS.keys():
        results[lang] = load_results(lang)
    
    # Generate markdown sections
    sections = [
        "# ONNX Runtime Benchmarks (768D)\n",
        "This document contains aggregated benchmark results comparing hash-based and ONNX embeddings across all language bindings.\n",
        "**Note**: ONNX model only supports 768 dimensions.\n",
        generate_summary(results),
        generate_speed_comparison_table(results),
        generate_memory_comparison_table(results),
        generate_quality_table(results),
        generate_batch_performance_table(results),
        "## Test Methodology\n",
        "- **Text sizes**: Short (~100 chars), Medium (~500 chars), Long (~2000 chars)",
        "- **Dimension**: 768 (ONNX model limitation)",
        "- **Batch sizes**: 1, 10, 100",
        "- **Metrics**: Speed (ms), Memory (MB), Quality (cosine similarity)\n"
    ]
    
    # Write to file
    output_path = Path(__file__).parent.parent / "BENCHMARK_RESULTS.md"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("\n\n".join(sections))
    
    print(f"Results aggregated and written to: {output_path}")

if __name__ == "__main__":
    main()

