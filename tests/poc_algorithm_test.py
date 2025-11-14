#!/usr/bin/env python3
"""
Proof of Concept: Hash-Based Embedding Algorithm
=================================================

Pure Python implementation to verify algorithm correctness independently
from Assembly implementation.

Algorithm:
1. Positional hash with character position weighting
2. Combined hash using two hash values with XOR
3. MurmurHash3-style finalization for better distribution
4. Linear transformation to [-1, 1] range

This POC tests:
- Determinism (same text → same embedding)
- Distribution (different texts → different embeddings)
- Range (values in [-1, 1])
- Positional sensitivity (character order matters)
"""

import struct
import math
from typing import List


# ============================================================================
# Core Hash Functions
# ============================================================================

def positional_hash(text: str, seed: int) -> int:
    """
    Positional hash with character position weighting.
    
    Algorithm:
        hash = seed * 31 + Σ(char_i * (i+1) * 31^(n-i-1))
    
    Args:
        text: Input text
        seed: Hash seed
        
    Returns:
        64-bit unsigned hash value
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
    
    Algorithm:
        hash1 = positional_hash(text, seed)
        hash2 = positional_hash(text, seed * 37)
        combined = hash1 XOR (hash2 << 16)
    
    Args:
        text: Input text
        seed: Hash seed
        
    Returns:
        64-bit combined hash value
    """
    hash1 = positional_hash(text, seed)
    hash2 = positional_hash(text, seed * 37)
    
    # Combine using XOR with bit shift
    combined = hash1 ^ ((hash2 << 16) & 0xFFFFFFFFFFFFFFFF)
    
    return combined


# ============================================================================
# MurmurHash3 Finalization
# ============================================================================

def murmur3_finalize(hash_value: int) -> int:
    """
    MurmurHash3 finalizer for better bit distribution.
    
    This mixing function ensures that even small hash differences
    result in well-distributed output values.
    
    Args:
        hash_value: 64-bit input hash
        
    Returns:
        64-bit finalized hash with better distribution
    """
    # Mix bits using MurmurHash3 finalizer
    h = hash_value
    h ^= h >> 33
    h = (h * 0xFF51AFD7ED558CCD) & 0xFFFFFFFFFFFFFFFF
    h ^= h >> 33
    h = (h * 0xC4CEB9FE1A85EC53) & 0xFFFFFFFFFFFFFFFF
    h ^= h >> 33
    
    return h


def hash_to_float(hash_value: int) -> float:
    """
    Convert hash to float in [-1, 1] range.
    
    Algorithm:
        1. Apply MurmurHash3 finalization
        2. Take 31 bits (positive range)
        3. Normalize to [0, 1): value / 2^31
        4. Scale to [-1, 1]: value * 2 - 1
    
    Args:
        hash_value: 64-bit input hash
        
    Returns:
        Float value in [-1, 1] range
    """
    # Apply MurmurHash3 finalization
    finalized = murmur3_finalize(hash_value)
    
    # Take 31 bits (positive range)
    value = finalized & 0x7FFFFFFF
    
    # Normalize to [0, 1)
    normalized = value / (2**31)
    
    # Scale to [-1, 1)
    result = normalized * 2.0 - 1.0
    
    return result


# ============================================================================
# Embedding Generation
# ============================================================================

def generate_embedding(text: str, dimension: int = 128) -> List[float]:
    """
    Generate hash-based embedding for text.
    
    Algorithm:
        For each dimension i:
            hash = combined_hash(text, seed=i)
            embedding[i] = hash_to_float(hash)
    
    Args:
        text: Input text
        dimension: Embedding dimension (default: 128)
        
    Returns:
        List of float values in [-1, 1] range
    """
    if not text:
        raise ValueError("Text cannot be empty")
    
    embedding = []
    for i in range(dimension):
        hash_value = generate_combined_hash(text, seed=i)
        value = hash_to_float(hash_value)
        embedding.append(value)
    
    return embedding


# ============================================================================
# Vector Operations
# ============================================================================

def dot_product(vec1: List[float], vec2: List[float]) -> float:
    """Calculate dot product of two vectors."""
    return sum(a * b for a, b in zip(vec1, vec2))


def vector_norm(vec: List[float]) -> float:
    """Calculate Euclidean norm of vector."""
    return math.sqrt(sum(x * x for x in vec))


def cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """
    Calculate cosine similarity between two vectors.
    
    similarity = (vec1 · vec2) / (||vec1|| * ||vec2||)
    
    Returns:
        Similarity value in [-1, 1] range
    """
    dot = dot_product(vec1, vec2)
    norm1 = vector_norm(vec1)
    norm2 = vector_norm(vec2)
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot / (norm1 * norm2)


# ============================================================================
# Tests
# ============================================================================

def test_determinism():
    """Test: Same text produces identical embedding."""
    print("\n=== Test 1: Determinism ===")
    
    text = "Hello, world!"
    emb1 = generate_embedding(text, dimension=128)
    emb2 = generate_embedding(text, dimension=128)
    
    # Check if embeddings are identical
    identical = all(abs(a - b) < 1e-10 for a, b in zip(emb1, emb2))
    
    if identical:
        print("✅ PASS: Same text produces identical embedding")
    else:
        print("❌ FAIL: Embeddings differ for same text!")
        max_diff = max(abs(a - b) for a, b in zip(emb1, emb2))
        print(f"   Max difference: {max_diff}")
    
    return identical


def test_range():
    """Test: All values are in [-1, 1] range."""
    print("\n=== Test 2: Range [-1, 1] ===")
    
    texts = [
        "Hello",
        "World",
        "The quick brown fox jumps over the lazy dog",
        "12345",
        "!@#$%",
        "Текст на русском",
        "a" * 1000,  # Long text
    ]
    
    all_in_range = True
    for text in texts:
        emb = generate_embedding(text, dimension=128)
        
        min_val = min(emb)
        max_val = max(emb)
        
        in_range = -1.0 <= min_val <= 1.0 and -1.0 <= max_val <= 1.0
        
        if not in_range:
            print(f"❌ FAIL: '{text[:30]}...' - values out of range")
            print(f"   Min: {min_val}, Max: {max_val}")
            all_in_range = False
    
    if all_in_range:
        print("✅ PASS: All values in [-1, 1] range")
    
    return all_in_range


def test_distribution():
    """Test: Different texts produce different embeddings."""
    print("\n=== Test 3: Distribution ===")
    
    texts = [
        "Hello",
        "World",
        "FastEmbed",
        "Python",
        "Algorithm",
        "Testing",
        "Embedding",
        "Vector",
        "Similarity",
        "Distribution",
    ]
    
    embeddings = [generate_embedding(text, dimension=128) for text in texts]
    
    # Check pairwise similarities
    different_count = 0
    total_pairs = 0
    similarities = []
    
    for i in range(len(texts)):
        for j in range(i + 1, len(texts)):
            sim = cosine_similarity(embeddings[i], embeddings[j])
            similarities.append(sim)
            total_pairs += 1
            
            # Different texts should have low similarity
            if sim < 0.8:
                different_count += 1
    
    avg_similarity = sum(similarities) / len(similarities)
    min_similarity = min(similarities)
    max_similarity = max(similarities)
    
    print(f"Average similarity: {avg_similarity:.4f}")
    print(f"Min similarity: {min_similarity:.4f}")
    print(f"Max similarity: {max_similarity:.4f}")
    print(f"Different pairs: {different_count}/{total_pairs}")
    
    # At least 90% of pairs should be different (similarity < 0.8)
    success = (different_count / total_pairs) >= 0.9
    
    if success:
        print("✅ PASS: Different texts produce different embeddings")
    else:
        print("❌ FAIL: Too many similar embeddings")
    
    return success


def test_positional_sensitivity():
    """Test: Character order affects embedding."""
    print("\n=== Test 4: Positional Sensitivity ===")
    
    text1 = "Hello world"
    text2 = "world Hello"
    
    emb1 = generate_embedding(text1, dimension=128)
    emb2 = generate_embedding(text2, dimension=128)
    
    similarity = cosine_similarity(emb1, emb2)
    
    print(f"Similarity between '{text1}' and '{text2}': {similarity:.4f}")
    
    # Reordered texts should have moderate similarity (not too high, not too low)
    success = 0.3 < similarity < 0.9
    
    if success:
        print("✅ PASS: Positional sensitivity works correctly")
        print(f"   (Expected range: 0.3-0.9, Got: {similarity:.4f})")
    else:
        print("❌ FAIL: Similarity out of expected range")
        if similarity >= 0.9:
            print("   (Too similar - position not affecting enough)")
        else:
            print("   (Too different - may be over-sensitive)")
    
    return success


def test_typo_detection():
    """Test: Small differences produce moderately different embeddings."""
    print("\n=== Test 5: Typo Detection ===")
    
    pairs = [
        ("Hello", "Helo"),      # 1 char removed
        ("World", "Wrold"),     # 2 chars swapped
        ("Python", "Pyton"),    # 1 char removed
        ("Testing", "Testin"),  # 1 char removed
    ]
    
    similarities = []
    for text1, text2 in pairs:
        emb1 = generate_embedding(text1, dimension=128)
        emb2 = generate_embedding(text2, dimension=128)
        sim = cosine_similarity(emb1, emb2)
        similarities.append(sim)
        print(f"  '{text1}' vs '{text2}': {sim:.4f}")
    
    avg_sim = sum(similarities) / len(similarities)
    
    # Typos should produce moderate similarity (0.5-0.85)
    success = 0.5 < avg_sim < 0.85
    
    if success:
        print(f"✅ PASS: Average similarity {avg_sim:.4f} in expected range [0.5, 0.85]")
    else:
        print(f"❌ FAIL: Average similarity {avg_sim:.4f} out of range")
    
    return success


def test_hash_distribution():
    """Test: Hash function produces well-distributed values."""
    print("\n=== Test 6: Hash Distribution ===")
    
    # Generate hashes for sequential seeds
    hashes = []
    for i in range(100):
        h = generate_combined_hash("test", seed=i)
        hashes.append(h)
    
    # Convert to floats
    floats = [hash_to_float(h) for h in hashes]
    
    # Check distribution properties
    mean = sum(floats) / len(floats)
    variance = sum((x - mean) ** 2 for x in floats) / len(floats)
    std_dev = math.sqrt(variance)
    
    min_val = min(floats)
    max_val = max(floats)
    
    print(f"Mean: {mean:.4f} (expected ≈ 0)")
    print(f"Std Dev: {std_dev:.4f} (expected ≈ 0.577 for uniform [-1,1])")
    print(f"Min: {min_val:.4f}")
    print(f"Max: {max_val:.4f}")
    
    # Good distribution: mean close to 0, std dev ~0.577
    success = abs(mean) < 0.2 and 0.4 < std_dev < 0.8
    
    if success:
        print("✅ PASS: Hash distribution is good")
    else:
        print("❌ FAIL: Hash distribution is poor")
    
    return success


def test_case_insensitivity():
    """Test: Case-insensitive behavior."""
    print("\n=== Test 7: Case Insensitivity ===")
    
    variants = ["Hello", "hello", "HELLO", "HeLLo"]
    embeddings = [generate_embedding(text, dimension=128) for text in variants]
    
    # All should be identical
    all_identical = True
    for i in range(1, len(embeddings)):
        identical = all(abs(a - b) < 1e-10 for a, b in zip(embeddings[0], embeddings[i]))
        if not identical:
            all_identical = False
            print(f"❌ '{variants[0]}' vs '{variants[i]}': Different!")
    
    if all_identical:
        print("✅ PASS: All case variants produce identical embeddings")
    
    return all_identical


# ============================================================================
# Main Test Runner
# ============================================================================

def run_all_tests():
    """Run all POC tests."""
    print("=" * 70)
    print("FastEmbed Algorithm POC - Test Suite")
    print("=" * 70)
    
    tests = [
        test_determinism,
        test_range,
        test_distribution,
        test_positional_sensitivity,
        test_typo_detection,
        test_hash_distribution,
        test_case_insensitivity,
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"❌ EXCEPTION: {e}")
            results.append(False)
    
    # Summary
    print("\n" + "=" * 70)
    print("Test Summary")
    print("=" * 70)
    passed = sum(results)
    total = len(results)
    print(f"Tests passed: {passed}/{total}")
    
    if passed == total:
        print("\n🎉 ALL TESTS PASSED! Algorithm is working correctly.")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed. Check algorithm implementation.")
    
    return passed == total


# ============================================================================
# Example Usage
# ============================================================================

def example_usage():
    """Demonstrate algorithm usage."""
    print("\n" + "=" * 70)
    print("Example Usage")
    print("=" * 70)
    
    # Generate embeddings
    text1 = "The quick brown fox"
    text2 = "The lazy dog"
    
    emb1 = generate_embedding(text1, dimension=128)
    emb2 = generate_embedding(text2, dimension=128)
    
    print(f"\nText 1: '{text1}'")
    print(f"Embedding: [{emb1[0]:.4f}, {emb1[1]:.4f}, ..., {emb1[-1]:.4f}]")
    
    print(f"\nText 2: '{text2}'")
    print(f"Embedding: [{emb2[0]:.4f}, {emb2[1]:.4f}, ..., {emb2[-1]:.4f}]")
    
    # Calculate similarity
    sim = cosine_similarity(emb1, emb2)
    print(f"\nCosine similarity: {sim:.4f}")


if __name__ == "__main__":
    # Run tests
    success = run_all_tests()
    
    # Show example
    example_usage()
    
    # Exit with appropriate code
    exit(0 if success else 1)

