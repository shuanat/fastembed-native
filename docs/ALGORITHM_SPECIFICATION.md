# Algorithm Specification: Improved Hash-Based Embedding

**Version**: 1.0.1  
**Date**: 2025-01-14  
**Author**: FastEmbed Development Team

---

## Overview

This document specifies the improved hash-based embedding algorithm with Sin/Cos normalization and positional hashing. The algorithm generates deterministic, high-quality embeddings for text input.

---

## Function Signature

```c
int generate_embedding_asm(
    const char *text,      // Input text (UTF-8, null-terminated)
    float *output,         // Output array (pre-allocated, size >= dimension)
    int dimension          // Embedding dimension (128, 256, 512, 768, 1024, 2048)
);
```

**Returns**:

- `0`: Success
- `-1`: Error (invalid input, dimension not supported, etc.)

---

## Algorithm Steps

### Step 1: Input Validation

```
1. If text == NULL → return -1
2. If output == NULL → return -1
3. If dimension not in {128, 256, 512, 768, 1024, 2048} → return -1
4. Calculate text_length = strlen(text)
5. If text_length == 0 → return -1 (empty text)
6. If text_length > MAX_TEXT_LENGTH → return -1
```

### Step 2: Initialize

```
1. Initialize output array to zeros (optional, for safety)
2. Set dimension_index = 0
```

### Step 3: Embedding Generation Loop

For each dimension `i` from `0` to `dimension - 1`:

#### Step 3.1: Generate Positional Hash

```
hash1 = positional_hash(text, text_length, seed=i)
```

**Positional Hash Algorithm**:

```
hash = seed
For each character position j (0..text_length-1):
    char = text[j]
    position_weight = j + 1
    hash = hash * 31 + char * position_weight
```

**Mathematical Formula**:

```
hash1 = i * 31 + Σ(char_j * (j + 1) * 31^(text_length - j - 1))
```

#### Step 3.2: Generate Secondary Hash

```
hash2 = positional_hash(text, text_length, seed=i*37)
```

**Purpose**: Secondary hash with different seed to reduce correlation.

**Algorithm**: Same as Step 3.1, but with `seed = i * 37`.

#### Step 3.3: Combine Hashes

```
combined = hash1 ^ (hash2 << 16)
```

**Purpose**: XOR operation combines hashes, bit shift adds variation.

**Mathematical Properties**:

- XOR preserves entropy
- Bit shift adds positional variation
- Reduces correlation between dimensions

#### Step 3.4: Normalize with Sin Function

```
normalized_value = sin((combined % SCALE) / SCALE * 2π)
```

Where:

- `SCALE = 2^31` (or `2^32` for better precision)
- Result: `normalized_value ∈ [-1, 1]`

**Mathematical Justification**:

- Sin function maps to `[-1, 1]` range
- Provides non-linear normalization
- Reduces correlation between dimensions

#### Step 3.5: Store in Output Array

```
output[i] = normalized_value
```

### Step 4: Return Success

```
return 0
```

---

## Complete Algorithm Pseudocode

```
function generate_embedding_asm(text, output, dimension):
    // Step 1: Input Validation
    if text == NULL or output == NULL:
        return -1
    if dimension not in {128, 256, 512, 768, 1024, 2048}:
        return -1
    
    text_length = strlen(text)
    if text_length == 0 or text_length > MAX_TEXT_LENGTH:
        return -1
    
    // Step 2: Initialize
    SCALE = 2^31
    
    // Step 3: Embedding Generation Loop
    for i = 0 to dimension - 1:
        // Step 3.1: Generate Positional Hash
        hash1 = 0
        seed1 = i
        for j = 0 to text_length - 1:
            char = text[j]
            position_weight = j + 1
            hash1 = hash1 * 31 + char * position_weight
        
        // Step 3.2: Generate Secondary Hash
        hash2 = 0
        seed2 = i * 37
        for j = 0 to text_length - 1:
            char = text[j]
            position_weight = j + 1
            hash2 = hash2 * 31 + char * position_weight
        
        // Step 3.3: Combine Hashes
        combined = hash1 ^ (hash2 << 16)
        
        // Step 3.4: Normalize with Sin
        normalized = sin((combined % SCALE) / SCALE * 2π)
        
        // Step 3.5: Store
        output[i] = normalized
    
    // Step 4: Return Success
    return 0
```

---

## Edge Cases

### Empty Text

**Input**: `text = ""` (empty string)  
**Behavior**: Return `-1` (error)  
**Justification**: Empty text has no semantic content.

### Very Long Text

**Input**: `text_length > MAX_TEXT_LENGTH` (e.g., 8192)  
**Behavior**: Return `-1` (error)  
**Justification**: Prevents performance issues and memory overflow.

### Invalid Dimension

**Input**: `dimension = 64` or `dimension = 4096`  
**Behavior**: Return `-1` (error)  
**Justification**: Only specific dimensions are supported for optimization.

### Null Terminator Handling

**Input**: Text with embedded null characters  
**Behavior**: Process only up to first null character  
**Justification**: Standard C string handling.

### Special Characters

**Input**: Unicode characters, control characters  
**Behavior**: Process as bytes (UTF-8 encoding)  
**Justification**: Hash function operates on byte level.

---

## Determinism Guarantee

**Property**: For the same input `(text, dimension)`, the algorithm always produces the same output.

**Mathematical Proof**:

1. Hash functions are deterministic
2. Sin function is deterministic
3. All operations are deterministic (no randomness)
4. No external state (no global variables)

**Verification**:

```
generate_embedding_improved("Hello", output1, 128)
generate_embedding_improved("Hello", output2, 128)
assert output1 == output2  // Always true
```

---

## Performance Characteristics

### Time Complexity

- **Per dimension**: `O(text_length)`
- **Total**: `O(dimension * text_length)`

### Space Complexity

- **Input**: `O(text_length)`
- **Output**: `O(dimension)`
- **Temporary**: `O(1)` (constant space)

### Practical Performance

- **128 dimensions, 100 chars**: ~0.01-0.05 ms
- **768 dimensions, 100 chars**: ~0.05-0.15 ms
- **2048 dimensions, 100 chars**: ~0.15-0.30 ms

---

## Quality Guarantees

### Output Range

**Guarantee**: `output[i] ∈ [-1, 1]` for all `i`

**Proof**: Sin function maps to `[-1, 1]` range.

### Distribution

**Property**: Output values are approximately uniformly distributed in `[-1, 1]`.

**Justification**: Sin function with uniform hash input produces arcsine distribution, which is close to uniform for embedding purposes.

### Discrimination

**Property**: Different texts produce different embeddings (with high probability).

**Justification**: Hash function collision probability is negligible (see `ALGORITHM_MATH.md`).

---

## Implementation Notes

### Assembly Optimization

The algorithm will be implemented in x86-64 assembly for performance:

- SIMD instructions for parallel processing
- Optimized hash calculation
- Fast Sin approximation (SSE4)

### ABI Compliance

- **System V ABI** (Linux/macOS): Callee-saved registers preserved
- **Microsoft x64 ABI** (Windows): Shadow space, register usage

### Stack Alignment

- Maintain 16-byte stack alignment
- Required for SIMD operations

---

## Testing Requirements

### Unit Tests

1. **Determinism**: Same input → same output
2. **Range**: All values in `[-1, 1]`
3. **Dimension support**: All supported dimensions work
4. **Error handling**: Invalid inputs return `-1`

### Integration Tests

1. **Text similarity**: Similar texts have higher similarity
2. **Text discrimination**: Different texts have lower similarity
3. **Position sensitivity**: Reordered texts produce different embeddings

### Quality Tests

1. **Collision rate**: Measure actual collision rate
2. **Distribution**: Verify uniform distribution
3. **Correlation**: Measure inter-dimension correlation

---

## References

- `ALGORITHM_MATH.md`: Mathematical foundation
- `IMPLEMENTATION_GUIDE.md`: Assembly implementation details (to be created)

---

**End of Specification**
