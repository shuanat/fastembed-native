#!/usr/bin/env python3
"""
Alternative Mathematical Normalization Functions for Hash-Based Embeddings
===========================================================================

Testing different mathematical functions to improve similarity for similar texts.

Problem: Current approaches (Sin/Cos, MurmurHash3) produce nearly orthogonal
vectors (similarity ~0.02) for similar texts when we need 0.3-0.9.

Alternatives to test:
1. Tanh (Hyperbolic Tangent) - smoother than sin
2. Sigmoid - S-shaped curve
3. Smoothstep - polynomial smoothing
4. Logarithmic scaling
5. Power functions (sqrt, cubic, etc.)
6. Hybrid approaches
"""

import math
from typing import List, Callable


# ============================================================================
# Core Hash Functions (reused from previous POCs)
# ============================================================================

def positional_hash(text: str, seed: int) -> int:
    """Positional hash with character position weighting."""
    hash_value = seed
    text_bytes = text.lower().encode('utf-8')
    
    for i, byte_val in enumerate(text_bytes):
        position_weight = i + 1
        hash_value = (hash_value * 31 + byte_val * position_weight) & 0xFFFFFFFFFFFFFFFF
    
    return hash_value


def generate_combined_hash(text: str, seed: int) -> int:
    """Generate combined hash using two positional hashes."""
    hash1 = positional_hash(text, seed)
    hash2 = positional_hash(text, seed * 37)
    combined = hash1 ^ ((hash2 << 16) & 0xFFFFFFFFFFFFFFFF)
    return combined


# ============================================================================
# Alternative Normalization Functions
# ============================================================================

def normalize_to_01(hash_value: int) -> float:
    """Normalize hash to [0, 1) range."""
    # Use 31 bits for positive range
    value = hash_value & 0x7FFFFFFF
    return value / (2**31)


# 1. Tanh (Hyperbolic Tangent)
def hash_to_float_tanh(hash_value: int) -> float:
    """
    Use tanh for normalization.
    
    tanh(x) maps (-∞, ∞) → [-1, 1]
    Properties:
    - Smoother than sin
    - S-shaped curve
    - Saturates at extremes
    """
    normalized = normalize_to_01(hash_value)
    # Scale to wider range for tanh input (-3 to 3 gives good spread)
    scaled = (normalized * 6.0) - 3.0  # [-3, 3]
    return math.tanh(scaled)


# 2. Sigmoid (Logistic Function)
def hash_to_float_sigmoid(hash_value: int) -> float:
    """
    Use sigmoid for normalization.
    
    sigmoid(x) = 1 / (1 + e^(-x))
    Maps (-∞, ∞) → (0, 1), then shift to [-1, 1]
    
    Properties:
    - S-shaped curve
    - Smooth transitions
    - Probabilistic interpretation
    """
    normalized = normalize_to_01(hash_value)
    # Scale to wider range for sigmoid input
    scaled = (normalized * 12.0) - 6.0  # [-6, 6]
    sigmoid = 1.0 / (1.0 + math.exp(-scaled))
    # Map [0, 1] → [-1, 1]
    return sigmoid * 2.0 - 1.0


# 3. Smoothstep (Polynomial Interpolation)
def hash_to_float_smoothstep(hash_value: int) -> float:
    """
    Use smoothstep for normalization.
    
    smoothstep(x) = 3x² - 2x³  (for x in [0,1])
    
    Properties:
    - Smooth acceleration/deceleration
    - Derivatives are 0 at endpoints
    - Often used in graphics
    """
    x = normalize_to_01(hash_value)
    # Smoothstep: 3x² - 2x³
    smooth = 3.0 * x * x - 2.0 * x * x * x
    # Map [0, 1] → [-1, 1]
    return smooth * 2.0 - 1.0


# 4. Smootherstep (Ken Perlin's improved version)
def hash_to_float_smootherstep(hash_value: int) -> float:
    """
    Use smootherstep (Perlin's improvement).
    
    smootherstep(x) = 6x⁵ - 15x⁴ + 10x³
    
    Properties:
    - Even smoother than smoothstep
    - Zero 1st and 2nd derivatives at endpoints
    - Better continuity
    """
    x = normalize_to_01(hash_value)
    # Smootherstep: 6x⁵ - 15x⁴ + 10x³
    smoother = 6.0 * x**5 - 15.0 * x**4 + 10.0 * x**3
    # Map [0, 1] → [-1, 1]
    return smoother * 2.0 - 1.0


# 5. Square Root (Power Function)
def hash_to_float_sqrt(hash_value: int) -> float:
    """
    Use square root for normalization.
    
    sqrt(x) maps [0, 1] → [0, 1] with compression
    
    Properties:
    - Compresses high values
    - Non-linear but simple
    - Fast to compute
    """
    x = normalize_to_01(hash_value)
    sqrt_val = math.sqrt(x)
    # Map [0, 1] → [-1, 1]
    return sqrt_val * 2.0 - 1.0


# 6. Cubic (Power Function)
def hash_to_float_cubic(hash_value: int) -> float:
    """
    Use cubic for normalization.
    
    x³ maps [-1, 1] → [-1, 1] with compression near 0
    
    Properties:
    - Preserves sign
    - Compresses middle values
    - Expands extremes
    """
    x = normalize_to_01(hash_value)
    # Map to [-1, 1] first
    centered = x * 2.0 - 1.0
    # Apply cubic
    return centered ** 3


# 7. Logarithmic Scaling
def hash_to_float_log(hash_value: int) -> float:
    """
    Use logarithmic scaling.
    
    log(1 + x) provides compression
    
    Properties:
    - Compresses large values
    - Expands small values
    - Natural for many distributions
    """
    x = normalize_to_01(hash_value)
    # log(1 + x) maps [0, 1] → [0, log(2)]
    log_val = math.log(1.0 + x) / math.log(2.0)  # Normalize by log(2)
    # Map to [-1, 1]
    return log_val * 2.0 - 1.0


# 8. Exponential Decay
def hash_to_float_exp(hash_value: int) -> float:
    """
    Use exponential decay.
    
    e^(-x) provides decay
    
    Properties:
    - Fast decay at start
    - Slow decay later
    - Asymmetric
    """
    x = normalize_to_01(hash_value)
    # e^(-x) maps [0, 1] → [1, 1/e]
    exp_val = math.exp(-x)
    # Normalize to [0, 1]
    normalized = (exp_val - math.exp(-1)) / (1.0 - math.exp(-1))
    # Map to [-1, 1]
    return normalized * 2.0 - 1.0


# 9. Atan (Arctangent)
def hash_to_float_atan(hash_value: int) -> float:
    """
    Use atan for normalization.
    
    atan(x) maps (-∞, ∞) → (-π/2, π/2)
    
    Properties:
    - Smooth S-curve
    - Similar to tanh but different scale
    - Bounded output
    """
    normalized = normalize_to_01(hash_value)
    # Scale to wider range
    scaled = (normalized * 10.0) - 5.0  # [-5, 5]
    atan_val = math.atan(scaled)
    # Map from [-π/2, π/2] to [-1, 1]
    return atan_val / (math.pi / 2.0)


# 10. Linear (Baseline for comparison)
def hash_to_float_linear(hash_value: int) -> float:
    """
    Linear normalization (baseline).
    
    Simple linear mapping [0, 1] → [-1, 1]
    """
    x = normalize_to_01(hash_value)
    return x * 2.0 - 1.0


# ============================================================================
# Embedding Generation
# ============================================================================

def generate_embedding(text: str, dimension: int, norm_func: Callable) -> List[float]:
    """Generate embedding using specified normalization function."""
    if not text:
        raise ValueError("Text cannot be empty")
    
    embedding = []
    for i in range(dimension):
        hash_value = generate_combined_hash(text, seed=i)
        value = norm_func(hash_value)
        embedding.append(value)
    
    return embedding


# ============================================================================
# Evaluation Functions
# ============================================================================

def cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """Calculate cosine similarity."""
    dot = sum(a * b for a, b in zip(vec1, vec2))
    norm1 = math.sqrt(sum(x * x for x in vec1))
    norm2 = math.sqrt(sum(y * y for y in vec2))
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot / (norm1 * norm2)


def evaluate_function(name: str, norm_func: Callable) -> dict:
    """Evaluate a normalization function."""
    print(f"\n{'='*70}")
    print(f"Evaluating: {name}")
    print('='*70)
    
    # Test cases
    test_pairs = [
        ("Hello world", "world Hello", "Reordered"),
        ("Hello", "Helo", "Typo 1 char"),
        ("World", "Wrold", "Typo swap"),
        ("Python", "Pyton", "Typo remove"),
        ("Hello world", "Goodbye world", "Different"),
        ("FastEmbed", "SlowEmbed", "Partial match"),
    ]
    
    results = {
        'name': name,
        'similarities': [],
        'labels': [],
    }
    
    for text1, text2, label in test_pairs:
        emb1 = generate_embedding(text1, 128, norm_func)
        emb2 = generate_embedding(text2, 128, norm_func)
        sim = cosine_similarity(emb1, emb2)
        
        results['similarities'].append(sim)
        results['labels'].append(label)
        
        print(f"  {label:20s}: {text1:20s} vs {text2:20s} → {sim:7.4f}")
    
    # Calculate averages
    reordered_sim = results['similarities'][0]
    typo_sims = results['similarities'][1:4]
    different_sims = results['similarities'][4:6]
    
    avg_typo = sum(typo_sims) / len(typo_sims)
    avg_different = sum(different_sims) / len(different_sims)
    
    print(f"\n  Average Typo Similarity:      {avg_typo:.4f}")
    print(f"  Average Different Similarity: {avg_different:.4f}")
    print(f"  Reordered Similarity:         {reordered_sim:.4f}")
    
    # Check if meets criteria
    typo_ok = 0.4 < avg_typo < 0.9
    reorder_ok = 0.2 < reordered_sim < 0.9
    different_ok = -0.5 < avg_different < 0.5
    
    score = sum([typo_ok, reorder_ok, different_ok])
    
    print(f"\n  Criteria:")
    print(f"    Typo tolerance [0.4, 0.9]:     {'✅' if typo_ok else '❌'}")
    print(f"    Reorder sensitivity [0.2, 0.9]: {'✅' if reorder_ok else '❌'}")
    print(f"    Different texts [-0.5, 0.5]:   {'✅' if different_ok else '❌'}")
    print(f"  Score: {score}/3")
    
    results['avg_typo'] = avg_typo
    results['avg_different'] = avg_different
    results['reordered_sim'] = reordered_sim
    results['score'] = score
    
    return results


# ============================================================================
# Main Evaluation
# ============================================================================

def run_comparison():
    """Run comparison of all normalization functions."""
    print("="*70)
    print("Alternative Normalization Functions Comparison")
    print("="*70)
    
    functions = [
        ("Linear (Baseline)", hash_to_float_linear),
        ("Tanh", hash_to_float_tanh),
        ("Sigmoid", hash_to_float_sigmoid),
        ("Smoothstep", hash_to_float_smoothstep),
        ("Smootherstep", hash_to_float_smootherstep),
        ("Square Root", hash_to_float_sqrt),
        ("Cubic", hash_to_float_cubic),
        ("Logarithmic", hash_to_float_log),
        ("Exponential", hash_to_float_exp),
        ("Atan", hash_to_float_atan),
    ]
    
    all_results = []
    
    for name, func in functions:
        results = evaluate_function(name, func)
        all_results.append(results)
    
    # Summary
    print("\n" + "="*70)
    print("SUMMARY - Ranked by Score")
    print("="*70)
    
    # Sort by score
    all_results.sort(key=lambda x: x['score'], reverse=True)
    
    print(f"\n{'Rank':<6}{'Function':<20}{'Score':<8}{'Typo':<10}{'Reorder':<10}{'Different':<10}")
    print("-"*70)
    
    for i, result in enumerate(all_results, 1):
        print(f"{i:<6}{result['name']:<20}{result['score']}/3      "
              f"{result['avg_typo']:<10.4f}{result['reordered_sim']:<10.4f}"
              f"{result['avg_different']:<10.4f}")
    
    # Best function
    best = all_results[0]
    print(f"\n🏆 Best Function: {best['name']} (Score: {best['score']}/3)")
    
    if best['score'] == 3:
        print("   ✅ Meets all criteria!")
    elif best['score'] == 2:
        print("   ⚠️  Meets 2/3 criteria - close!")
    else:
        print("   ❌ Needs improvement")
    
    return all_results


if __name__ == "__main__":
    results = run_comparison()
    exit(0)

