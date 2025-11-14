#!/usr/bin/env python3
"""
Proof of Concept: Original Sin/Cos Hash-Based Embedding Algorithm
===================================================================

This implements the ORIGINAL algorithm as described in ALGORITHM_MATH.md:
- Positional hashing with character position weighting
- Sin/Cos normalization (NOT MurmurHash3)
- Combined hash using two hash values with XOR

This POC tests whether the Sin/Cos approach works better than MurmurHash3.

Algorithm from ALGORITHM_MATH.md (lines 82-108):
    value = sin((hash % scale) / scale * 2π)
"""

import math
from typing import List


# ============================================================================
# Core Hash Functions (Same as MurmurHash3 version)
# ============================================================================

def positional_hash(text: str, seed: int) -> int:
    """
    Positional hash with character position weighting.
    
    Algorithm (from ALGORITHM_MATH.md line 69):
        hash_positional(text, seed) = seed * 31 + Σ(char_i * (i+1) * 31^(n-i-1))
    """
    hash_value = seed
    text_bytes = text.lower().encode('utf-8')  # Case-insensitive
    
    for i, byte_val in enumerate(text_bytes):
        position_weight = i + 1  # Position 0 → weight 1
        hash_value = (hash_value * 31 + byte_val * position_weight) & 0xFFFFFFFFFFFFFFFF
    
    return hash_value


def generate_combined_hash(text: str, seed: int) -> int:
    """
    Generate combined hash using two positional hashes.
    
    Algorithm (from ALGORITHM_MATH.md lines 404-409):
        hash1 = hash_positional(text, seed)
        hash2 = hash_positional(text, seed * 37)
        combined = hash1 ^ (hash2 << 16)
    """
    hash1 = positional_hash(text, seed)
    hash2 = positional_hash(text, seed * 37)
    
    # Combine using XOR with bit shift
    combined = hash1 ^ ((hash2 << 16) & 0xFFFFFFFFFFFFFFFF)
    
    return combined


# ============================================================================
# Sin/Cos Normalization (ORIGINAL APPROACH from ALGORITHM_MATH.md)
# ============================================================================

def hash_to_float_sin(hash_value: int) -> float:
    """
    Convert hash to float using SIN normalization.
    
    Algorithm (from ALGORITHM_MATH.md lines 88-90):
        value = sin((hash % scale) / scale * 2π)
    
    Where:
        - hash: Hash value (uint64)
        - scale: Normalization scale (2^32)
        - Result: value ∈ [-1, 1]
    
    Args:
        hash_value: 64-bit input hash
        
    Returns:
        Float value in [-1, 1] range
    """
    # Use 2^32 as scale (as mentioned in docs)
    scale = 2**32
    
    # Normalize hash to [0, 1)
    normalized = (hash_value % scale) / scale
    
    # Map to [0, 2π)
    angle = normalized * 2.0 * math.pi
    
    # Apply sin function → [-1, 1]
    value = math.sin(angle)
    
    return value


def hash_to_float_cos(hash_value: int) -> float:
    """
    Convert hash to float using COS normalization.
    
    Alternative to sin, mentioned in ALGORITHM_MATH.md title.
    
    Args:
        hash_value: 64-bit input hash
        
    Returns:
        Float value in [-1, 1] range
    """
    # Use 2^32 as scale
    scale = 2**32
    
    # Normalize hash to [0, 1)
    normalized = (hash_value % scale) / scale
    
    # Map to [0, 2π)
    angle = normalized * 2.0 * math.pi
    
    # Apply cos function → [-1, 1]
    value = math.cos(angle)
    
    return value


# ============================================================================
# Embedding Generation (Original Sin/Cos approach)
# ============================================================================

def generate_embedding_sin(text: str, dimension: int = 128) -> List[float]:
    """
    Generate hash-based embedding using SIN normalization.
    
    Algorithm (from ALGORITHM_MATH.md lines 414-417):
        For each dimension i (0..dimension-1):
          hash = combined_hash(text, seed=i)
          embedding[i] = sin((hash % scale) / scale * 2π)
    """
    if not text:
        raise ValueError("Text cannot be empty")
    
    embedding = []
    for i in range(dimension):
        hash_value = generate_combined_hash(text, seed=i)
        value = hash_to_float_sin(hash_value)
        embedding.append(value)
    
    return embedding


def generate_embedding_cos(text: str, dimension: int = 128) -> List[float]:
    """
    Generate hash-based embedding using COS normalization.
    
    Alternative version using cosine instead of sine.
    """
    if not text:
        raise ValueError("Text cannot be empty")
    
    embedding = []
    for i in range(dimension):
        hash_value = generate_combined_hash(text, seed=i)
        value = hash_to_float_cos(hash_value)
        embedding.append(value)
    
    return embedding


def generate_embedding_sincos_mixed(text: str, dimension: int = 128) -> List[float]:
    """
    Generate embedding using BOTH sin and cos (alternating).
    
    This provides more diversity:
    - Even dimensions: sin
    - Odd dimensions: cos
    """
    if not text:
        raise ValueError("Text cannot be empty")
    
    embedding = []
    for i in range(dimension):
        hash_value = generate_combined_hash(text, seed=i)
        
        # Alternate between sin and cos
        if i % 2 == 0:
            value = hash_to_float_sin(hash_value)
        else:
            value = hash_to_float_cos(hash_value)
        
        embedding.append(value)
    
    return embedding


# ============================================================================
# Vector Operations (same as before)
# ============================================================================

def dot_product(vec1: List[float], vec2: List[float]) -> float:
    """Calculate dot product of two vectors."""
    return sum(a * b for a, b in zip(vec1, vec2))


def vector_norm(vec: List[float]) -> float:
    """Calculate Euclidean norm of vector."""
    return math.sqrt(sum(x * x for x in vec))


def cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """Calculate cosine similarity between two vectors."""
    dot = dot_product(vec1, vec2)
    norm1 = vector_norm(vec1)
    norm2 = vector_norm(vec2)
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot / (norm1 * norm2)


# ============================================================================
# Tests for Sin/Cos approach
# ============================================================================

def test_determinism(embedding_func, name="Sin"):
    """Test: Same text produces identical embedding."""
    print(f"\n=== Test 1: Determinism ({name}) ===")
    
    text = "Hello, world!"
    emb1 = embedding_func(text, dimension=128)
    emb2 = embedding_func(text, dimension=128)
    
    identical = all(abs(a - b) < 1e-10 for a, b in zip(emb1, emb2))
    
    if identical:
        print(f"✅ PASS: Same text produces identical embedding")
    else:
        print(f"❌ FAIL: Embeddings differ for same text!")
    
    return identical


def test_range(embedding_func, name="Sin"):
    """Test: All values are in [-1, 1] range."""
    print(f"\n=== Test 2: Range [-1, 1] ({name}) ===")
    
    texts = [
        "Hello",
        "World",
        "The quick brown fox jumps over the lazy dog",
        "12345",
        "!@#$%",
        "a" * 1000,
    ]
    
    all_in_range = True
    for text in texts:
        emb = embedding_func(text, dimension=128)
        min_val = min(emb)
        max_val = max(emb)
        
        if not (-1.0 <= min_val <= 1.0 and -1.0 <= max_val <= 1.0):
            print(f"❌ FAIL: '{text[:30]}...' - out of range")
            all_in_range = False
    
    if all_in_range:
        print(f"✅ PASS: All values in [-1, 1] range")
    
    return all_in_range


def test_distribution(embedding_func, name="Sin"):
    """Test: Different texts produce different embeddings."""
    print(f"\n=== Test 3: Distribution ({name}) ===")
    
    texts = [
        "Hello", "World", "FastEmbed", "Python", "Algorithm",
        "Testing", "Embedding", "Vector", "Similarity", "Distribution"
    ]
    
    embeddings = [embedding_func(text, dimension=128) for text in texts]
    
    similarities = []
    for i in range(len(texts)):
        for j in range(i + 1, len(texts)):
            sim = cosine_similarity(embeddings[i], embeddings[j])
            similarities.append(sim)
    
    avg_similarity = sum(similarities) / len(similarities)
    min_similarity = min(similarities)
    max_similarity = max(similarities)
    
    print(f"Average similarity: {avg_similarity:.4f}")
    print(f"Min similarity: {min_similarity:.4f}")
    print(f"Max similarity: {max_similarity:.4f}")
    
    # Good distribution: low average similarity
    success = avg_similarity < 0.3
    
    if success:
        print(f"✅ PASS: Different texts produce different embeddings")
    else:
        print(f"❌ FAIL: Similarities too high (poor discrimination)")
    
    return success


def test_positional_sensitivity(embedding_func, name="Sin"):
    """Test: Character order affects embedding."""
    print(f"\n=== Test 4: Positional Sensitivity ({name}) ===")
    
    text1 = "Hello world"
    text2 = "world Hello"
    
    emb1 = embedding_func(text1, dimension=128)
    emb2 = embedding_func(text2, dimension=128)
    
    similarity = cosine_similarity(emb1, emb2)
    
    print(f"Similarity: {similarity:.4f}")
    
    # Expected range: 0.3-0.9 (moderate similarity)
    success = 0.3 < similarity < 0.9
    
    if success:
        print(f"✅ PASS: Positional sensitivity in expected range")
    else:
        print(f"❌ FAIL: Similarity {similarity:.4f} out of range [0.3, 0.9]")
    
    return success


def test_typo_tolerance(embedding_func, name="Sin"):
    """Test: Small differences produce moderately similar embeddings."""
    print(f"\n=== Test 5: Typo Tolerance ({name}) ===")
    
    pairs = [
        ("Hello", "Helo"),
        ("World", "Wrold"),
        ("Python", "Pyton"),
        ("Testing", "Testin"),
    ]
    
    similarities = []
    for text1, text2 in pairs:
        emb1 = embedding_func(text1, dimension=128)
        emb2 = embedding_func(text2, dimension=128)
        sim = cosine_similarity(emb1, emb2)
        similarities.append(sim)
        print(f"  '{text1}' vs '{text2}': {sim:.4f}")
    
    avg_sim = sum(similarities) / len(similarities)
    
    # Expected range: 0.5-0.85 (moderate similarity for typos)
    success = 0.5 < avg_sim < 0.85
    
    if success:
        print(f"✅ PASS: Average {avg_sim:.4f} in range [0.5, 0.85]")
    else:
        print(f"❌ FAIL: Average {avg_sim:.4f} out of range")
    
    return success


def test_hash_distribution(embedding_func, name="Sin"):
    """Test: Values are well-distributed."""
    print(f"\n=== Test 6: Hash Distribution ({name}) ===")
    
    floats = []
    for i in range(100):
        emb = embedding_func("test", dimension=1)
        # Just vary by seed change in next iteration
        h = generate_combined_hash("test", seed=i)
        if name == "Sin":
            floats.append(hash_to_float_sin(h))
        elif name == "Cos":
            floats.append(hash_to_float_cos(h))
    
    mean = sum(floats) / len(floats)
    variance = sum((x - mean) ** 2 for x in floats) / len(floats)
    std_dev = math.sqrt(variance)
    
    print(f"Mean: {mean:.4f} (expected ≈ 0)")
    print(f"Std Dev: {std_dev:.4f} (expected ≈ 0.577)")
    
    # Good distribution
    success = abs(mean) < 0.2 and 0.4 < std_dev < 0.8
    
    if success:
        print(f"✅ PASS: Distribution is good")
    else:
        print(f"❌ FAIL: Distribution is poor")
    
    return success


# ============================================================================
# Comparison Tests
# ============================================================================

def compare_approaches():
    """Compare Sin, Cos, and Mixed approaches."""
    print("\n" + "=" * 70)
    print("Comparison: Sin vs Cos vs Mixed")
    print("=" * 70)
    
    text1 = "Hello world"
    text2 = "world Hello"
    text3 = "Goodbye world"
    
    # Generate embeddings
    emb_sin_1 = generate_embedding_sin(text1, 128)
    emb_sin_2 = generate_embedding_sin(text2, 128)
    emb_sin_3 = generate_embedding_sin(text3, 128)
    
    emb_cos_1 = generate_embedding_cos(text1, 128)
    emb_cos_2 = generate_embedding_cos(text2, 128)
    emb_cos_3 = generate_embedding_cos(text3, 128)
    
    emb_mix_1 = generate_embedding_sincos_mixed(text1, 128)
    emb_mix_2 = generate_embedding_sincos_mixed(text2, 128)
    emb_mix_3 = generate_embedding_sincos_mixed(text3, 128)
    
    # Calculate similarities
    print("\nReordered texts ('Hello world' vs 'world Hello'):")
    print(f"  Sin:   {cosine_similarity(emb_sin_1, emb_sin_2):.4f}")
    print(f"  Cos:   {cosine_similarity(emb_cos_1, emb_cos_2):.4f}")
    print(f"  Mixed: {cosine_similarity(emb_mix_1, emb_mix_2):.4f}")
    
    print("\nDifferent texts ('Hello world' vs 'Goodbye world'):")
    print(f"  Sin:   {cosine_similarity(emb_sin_1, emb_sin_3):.4f}")
    print(f"  Cos:   {cosine_similarity(emb_cos_1, emb_cos_3):.4f}")
    print(f"  Mixed: {cosine_similarity(emb_mix_1, emb_mix_3):.4f}")


# ============================================================================
# Main Test Runner
# ============================================================================

def run_sin_tests():
    """Run tests for Sin approach."""
    print("=" * 70)
    print("Sin/Cos Algorithm POC - Original ALGORITHM_MATH.md Approach")
    print("=" * 70)
    
    print("\n" + "=" * 70)
    print("Testing: SIN Normalization")
    print("=" * 70)
    
    tests = [
        lambda: test_determinism(generate_embedding_sin, "Sin"),
        lambda: test_range(generate_embedding_sin, "Sin"),
        lambda: test_distribution(generate_embedding_sin, "Sin"),
        lambda: test_positional_sensitivity(generate_embedding_sin, "Sin"),
        lambda: test_typo_tolerance(generate_embedding_sin, "Sin"),
        lambda: test_hash_distribution(generate_embedding_sin, "Sin"),
    ]
    
    sin_results = [test() for test in tests]
    
    print("\n" + "=" * 70)
    print("Testing: COS Normalization")
    print("=" * 70)
    
    tests_cos = [
        lambda: test_determinism(generate_embedding_cos, "Cos"),
        lambda: test_range(generate_embedding_cos, "Cos"),
        lambda: test_distribution(generate_embedding_cos, "Cos"),
        lambda: test_positional_sensitivity(generate_embedding_cos, "Cos"),
        lambda: test_typo_tolerance(generate_embedding_cos, "Cos"),
        lambda: test_hash_distribution(generate_embedding_cos, "Cos"),
    ]
    
    cos_results = [test() for test in tests_cos]
    
    print("\n" + "=" * 70)
    print("Testing: MIXED Sin/Cos Normalization")
    print("=" * 70)
    
    tests_mixed = [
        lambda: test_determinism(generate_embedding_sincos_mixed, "Mixed"),
        lambda: test_range(generate_embedding_sincos_mixed, "Mixed"),
        lambda: test_distribution(generate_embedding_sincos_mixed, "Mixed"),
        lambda: test_positional_sensitivity(generate_embedding_sincos_mixed, "Mixed"),
        lambda: test_typo_tolerance(generate_embedding_sincos_mixed, "Mixed"),
    ]
    
    mixed_results = [test() for test in tests_mixed]
    
    # Summary
    print("\n" + "=" * 70)
    print("Test Summary")
    print("=" * 70)
    print(f"Sin approach:   {sum(sin_results)}/{len(sin_results)} passed")
    print(f"Cos approach:   {sum(cos_results)}/{len(cos_results)} passed")
    print(f"Mixed approach: {sum(mixed_results)}/{len(mixed_results)} passed")
    
    # Comparison
    compare_approaches()
    
    return all(sin_results) or all(cos_results) or all(mixed_results)


if __name__ == "__main__":
    success = run_sin_tests()
    exit(0 if success else 1)

