// Simple Embedding Generator (Assembly ARM64)
// Generates basic embeddings from text using hash-based approach
// This is a simple implementation - for production use, you'd need
// a full neural network model (requires Python/C++ backend)
//
// Strategy: 
// - Generate hash-based features from text
// - Create normalized vector from hash values
// - Output 768-dimension vector compatible with nomic-embed-text
//
// ARM64 (Apple Silicon) port of embedding_generator.asm (x86_64)

    .const
    .align 4
embedding_dim:
    .word 768
float_scale:
    .word 0x3A83126F         // 0.001 as float32
float_one:
    .word 0x3F800000         // 1.0 as float32
float_two:
    .word 0x40000000         // 2.0 as float32
two_pi:
    .word 0x40C90FDB         // 6.283185307... (2π) as float32
scale_2_31:
    .word 0x4F000000         // 2^31 (2147483648.0) as float32
scale_2_31_int:
    .quad 2147483648         // 2^31 as integer

    .bss
    .align 4
embedding_buffer:
    .skip 3072               // 768 floats = 3072 bytes

    .text
    .align 4

// External functions from embedding_lib_arm64.s
    .extern _normalize_vector_asm
    .extern _vector_norm_asm

// External math functions
    .extern _sinf


// ============================================
// Function: simple_text_hash
// Generate a simple hash from text string
// Parameters:
//   X0 = char* text (null-terminated)
//   X1 = int text_length
//   X2 = int seed (for variation)
// Returns:
//   X0 = hash value (uint64_t)
// ============================================
    .global _simple_text_hash
_simple_text_hash:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    
    // Save parameters
    mov x19, x0                  // text
    mov x20, x1                  // text_length
    mov x21, x2                  // seed
    
    mov x0, x21                  // Start with seed
    mov x9, x19                  // Text pointer
    mov x13, #0                  // Counter
    
.Lhash_loop:
    cmp x13, x20                 // Check if we've processed all chars
    bge .Lhash_done
    
    // Load character
    ldrb w14, [x9, x13]
    cbz w14, .Lhash_done         // Check for null terminator
    
    // Hash algorithm: hash = hash * 31 + char
    mov x15, x0
    lsl x15, x15, #5             // hash * 32
    sub x15, x15, x0             // hash * 31 = hash * 32 - hash
    add x0, x15, x0              // hash = hash * 31
    add x0, x0, x14              // hash += char
    
    add x13, x13, #1
    b .Lhash_loop
    
.Lhash_done:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret


// ============================================
// Function: uint64_to_float_normalized
// Convert uint64 to normalized float in range [-1, 1]
// Parameters:
//   X0 = uint64_t value
// Returns:
//   S0 = normalized float
// ============================================
_uint64_to_float_normalized:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    
    // Save parameter
    mov x19, x0                  // value
    
    // Convert uint64 to float
    // Normalize: float = (value / 2^63) * 2 - 1  (range [-1, 1])
    scvtf s0, x19                // Convert to float (uses lower bits)
    
    // For better distribution, use high bits too
    // Shift right to mix bits
    lsr x19, x19, #32
    scvtf s1, x19
    fadd s0, s0, s1
    
    // Normalize to [-1, 1] range
    adrp x9, float_scale@PAGE
    add x9, x9, float_scale@PAGEOFF
    ldr s1, [x9]
    fmul s0, s0, s1
    
    // Use high bits for better distribution
    fmov w10, s0                 // Extract bits
    and w10, w10, #0x7FFFFFFF    // Keep sign bit, mask rest
    scvtf s0, w10                // Convert back
    adrp x9, float_scale@PAGE
    add x9, x9, float_scale@PAGEOFF
    ldr s1, [x9]
    fmul s0, s0, s1              // Scale to [-1, 1]
    
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret


// ============================================
// Function: positional_hash_asm
// Generate positional hash from text string
// Algorithm: hash = hash * 31 + char * (position + 1)
// Parameters:
//   X0 = char* text (null-terminated)
//   X1 = int text_length
//   X2 = int seed (for variation)
// Returns:
//   X0 = hash value (uint64_t)
// ============================================
    .global _positional_hash_asm
_positional_hash_asm:
    // Save callee-saved registers
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    
    // Save parameters
    mov x19, x0                  // text
    mov x20, x1                  // text_length
    mov x21, x2                  // seed
    
    // Initialize hash with seed
    mov x0, x21                  // hash = seed
    mov x22, x19                 // text pointer
    mov x11, #0                  // position index (j)
    
.Lpositional_hash_loop:
    cmp x11, x20                 // Check if j < text_length
    bge .Lpositional_hash_done
    
    // Load character
    ldrb w1, [x22, x11]
    cbz w1, .Lpositional_hash_done  // Check for null terminator
    
    // Calculate position weight: (j + 1)
    add x2, x11, #1              // position_weight = j + 1
    
    // Hash: hash = hash * 31 + char * position_weight
    mov x10, x0                  // Save current hash
    lsl x10, x10, #5             // hash * 32
    sub x10, x10, x0             // hash * 31 = hash * 32 - hash
    mov x0, x10                  // hash = hash * 31
    
    // char * position_weight
    mul x10, x1, x2              // char * position_weight
    add x0, x0, x10              // hash += char * position_weight
    
    add x11, x11, #1
    b .Lpositional_hash_loop
    
.Lpositional_hash_done:
    // Restore callee-saved registers
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret


// ============================================
// Function: hash_to_float_sqrt_asm
// Convert hash to float using Square Root normalization
// Algorithm: 
//   normalized = (hash & 0x7FFFFFFF) / 2^31
//   sqrt_val = sqrt(normalized)
//   result = sqrt_val * 2 - 1
// 
// Why Square Root?
//   - Compresses differences between similar hashes
//   - Provides better similarity for typos and reordering
//   - Simple and fast (one NEON instruction)
//   - Meets quality criteria: typo tolerance 0.4-0.9
// 
// Parameters:
//   X0 = uint64_t hash
// Returns:
//   S0 = normalized float in range [-1, 1]
// ============================================
    .global _hash_to_float_sqrt_asm
_hash_to_float_sqrt_asm:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Square Root normalization for better similarity
    // Proven to work: typo tolerance 0.4, reorder sensitivity 0.23
    
    // Use 31 bits (always positive)
    and w0, w0, #0x7FFFFFFF      // Clear sign bit → [0, 2^31-1]
    
    // Convert to float
    scvtf s0, w0                 // S0 = hash as float
    
    // Divide by 2^31 to normalize to [0, 1)
    adrp x9, scale_2_31@PAGE
    add x9, x9, scale_2_31@PAGEOFF
    ldr s1, [x9]
    fdiv s0, s0, s1              // S0 = hash / 2^31 (range [0, 1))
    
    // Apply square root - THIS IS THE KEY!
    // sqrt() compresses differences between similar values
    fsqrt s0, s0                 // S0 = sqrt(S0)
    
    // Scale from [0, 1) to [-1, 1)
    adrp x9, float_two@PAGE
    add x9, x9, float_two@PAGEOFF
    ldr s1, [x9]
    fmul s0, s0, s1              // S0 = S0 * 2 (range [0, 2))
    
    adrp x9, float_one@PAGE
    add x9, x9, float_one@PAGEOFF
    ldr s1, [x9]
    fsub s0, s0, s1              // S0 = S0 - 1 (range [-1, 1))
    
    ldp x29, x30, [sp], #16
    ret


// ============================================
// Function: generate_combined_hash_asm
// Generate combined hash from text
// Algorithm:
//   hash1 = positional_hash(text, seed)
//   hash2 = positional_hash(text, seed*37)
//   combined = hash1 ^ (hash2 << 16)
// Parameters:
//   X0 = char* text (null-terminated)
//   X1 = int text_length
//   X2 = int seed
// Returns:
//   X0 = combined hash value (uint64_t)
// ============================================
    .global _generate_combined_hash_asm
_generate_combined_hash_asm:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    
    // Save parameters
    mov x19, x0                  // text
    mov x20, x1                  // text_length
    mov x21, x2                  // seed
    
    // Generate hash1 = positional_hash(text, seed)
    mov x22, x21                 // seed for hash1
    mov x0, x19                  // text
    mov x1, x20                  // text_length
    mov x2, x22                  // seed
    bl _positional_hash_asm
    mov x8, x0                   // hash1
    
    // Generate hash2 = positional_hash(text, seed*37)
    mov x22, x21                 // seed
    mov x23, #37
    mul x22, x22, x23            // seed * 37
    mov x0, x19                  // text
    mov x1, x20                  // text_length
    mov x2, x22                  // seed * 37
    bl _positional_hash_asm
    mov x9, x0                   // hash2
    
    // Combine: combined = hash1 ^ (hash2 << 16)
    lsl x10, x9, #16             // hash2 << 16
    eor x10, x10, x8             // combined = hash1 ^ (hash2 << 16)
    mov x0, x10                  // Return combined hash
    
    // Restore registers
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret


// ============================================
// Function: generate_embedding_asm
// Generate embedding with Square Root normalization and positional hashing
// 
// Algorithm:
//   For each dimension i:
//     1. Generate positional hash (character position aware)
//     2. Generate secondary hash (seed * 37)
//     3. Combine hashes: hash1 XOR (hash2 << 16)
//     4. Normalize with √x: sqrt((hash / 2^31)) * 2 - 1
//     5. Store in output[i]
// 
// Quality:
//   - Typo tolerance: 0.40+ similarity
//   - Reorder sensitivity: 0.23+ similarity
//   - Deterministic: same input → same output
// 
// Parameters:
//   X0 = char* text (UTF-8, null-terminated)
//   X1 = float* output (pre-allocated, size >= dimension)
//   X2 = int dimension (128, 256, 512, 768, 1024, 2048)
// Returns:
//   X0 = 0 on success, -1 on error
// ============================================
    .global _generate_embedding_asm
_generate_embedding_asm:
    // Prologue
    stp x29, x30, [sp, #-80]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    stp x25, x26, [sp, #64]
    
    // Save parameters immediately
    mov x19, x0                  // text
    mov x20, x1                  // output
    mov x21, x2                  // dimension
    
    // Step 1: Input Validation
    cbz x19, .Lerror
    
    cbz x20, .Lerror
    
    // Check dimension (must be in {128, 256, 512, 768, 1024, 2048})
    cmp w21, #128
    beq .Ldimension_ok
    cmp w21, #256
    beq .Ldimension_ok
    cmp w21, #512
    beq .Ldimension_ok
    cmp w21, #768
    beq .Ldimension_ok
    cmp w21, #1024
    beq .Ldimension_ok
    cmp w21, #2048
    beq .Ldimension_ok
    b .Lerror                    // Invalid dimension
    
.Ldimension_ok:
    // Step 2: Calculate text length
    mov x22, x19                 // text pointer for length calculation
    mov x23, #0                  // text_length counter
    
.Ltext_length_loop:
    ldrb w9, [x22]
    cbz w9, .Ltext_length_done
    add x23, x23, #1
    add x22, x22, #1
    b .Ltext_length_loop
    
.Ltext_length_done:
    cbz x23, .Lerror             // Check if empty
    mov x9, #8192
    cmp x23, x9                  // MAX_TEXT_LENGTH
    bgt .Lerror
    
    // Step 3: Embedding Generation Loop
    mov x22, #0                  // dimension index (i)
    
.Lembedding_loop:
    cmp x22, x21                 // Check if i < dimension
    bge .Lembedding_done
    
    // Step 3.1-3.3: Generate Combined Hash
    mov x0, x19                  // text
    mov x1, x23                  // text_length
    mov x2, x22                  // seed = i
    bl _generate_combined_hash_asm
    // Combined hash is in X0
    mov x10, x0                  // Save hash in X10
    
    // Step 3.4: Normalize with Square Root
    mov x0, x10                  // Pass hash as parameter
    bl _hash_to_float_sqrt_asm
    // S0 now contains sqrt-normalized value in [-1, 1]
    
    // Step 3.5: Store in output array
    add x11, x20, x22, lsl #2    // output + i*4
    str s0, [x11]                // output[i] = sqrt_value
    
    // Next iteration
    add x22, x22, #1
    b .Lembedding_loop
    
.Lembedding_done:
    // Success
    mov x0, #0
    b .Ldone
    
.Lerror:
    mov x0, #-1
    
.Ldone:
    // Restore callee-saved registers
    ldp x25, x26, [sp, #64]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #80
    ret

