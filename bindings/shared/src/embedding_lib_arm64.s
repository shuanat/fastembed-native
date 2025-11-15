// Embedding Library for Vector Search (Assembly ARM64)
// Provides NEON-optimized functions for embedding operations
//
// ARM64 (Apple Silicon) port of embedding_lib.asm (x86_64 SSE/AVX)
//
// To compile:
//   as -o embedding_lib_arm64.o embedding_lib_arm64.s (macOS)
//   gcc -c embedding_lib_arm64.s -o embedding_lib_arm64.o (Linux)
//
// To link:
//   gcc embedding_lib_arm64.o embedding_lib_c.c -o libfastembed.dylib (macOS)
//   gcc embedding_lib_arm64.o embedding_lib_c.c -o libfastembed.so (Linux)

    .const
    .align 4
float_one:
    .float 1.0
float_zero:
    .float 0.0
pi_constant:
    .float 3.14159265358979323846
embedding_dim:
    .word 768

    .bss
    .align 4
temp_vector:
    .skip 3072    // 768 floats = 3072 bytes

    .text
    .align 4

// ============================================
// Function: dot_product_asm
// Calculate dot product of two embedding vectors
// Parameters (AAPCS64):
//   X0 = float* vector_a (pointer to first vector)
//   X1 = float* vector_b (pointer to second vector)
//   X2 = int dimension (number of elements, typically 768)
// Returns:
//   S0 = dot product (float)
// ============================================
    .global _dot_product_asm
_dot_product_asm:
    // Prologue
    stp x29, x30, [sp, #-48]!   // Save frame pointer and link register
    mov x29, sp
    stp x19, x20, [sp, #16]     // Save callee-saved registers
    stp x21, x22, [sp, #32]
    
    // Save parameters to callee-saved registers
    mov x19, x0                  // vector_a
    mov x20, x1                  // vector_b
    mov x21, x2                  // dimension
    
    // Initialize accumulator to zero
    eor v0.16b, v0.16b, v0.16b   // V0 = 0.0 (all lanes)
    
    // Check if dimension is zero
    cbz x21, .Ldot_done
    
    // Calculate how many 4-float blocks we can process with NEON
    mov x9, x21                  // X9 = dimension
    and x9, x9, #0xFFFFFFFFFFFFFFFC  // X9 = dimension & ~3 (align to 4)
    
    // Process 4 floats at a time with NEON
    mov x10, #0                  // X10 = index counter
    
.Ldot_simd_loop:
    cmp x10, x9
    bge .Ldot_scalar_loop
    
    // Load 4 floats from vector_a
    add x11, x19, x10, lsl #2    // X11 = vector_a + index*4
    ld1 {v1.4s}, [x11]           // V1 = vector_a[i:i+4]
    
    // Load 4 floats from vector_b
    add x12, x20, x10, lsl #2    // X12 = vector_b + index*4
    ld1 {v2.4s}, [x12]           // V2 = vector_b[i:i+4]
    
    // Multiply and accumulate
    fmla v0.4s, v1.4s, v2.4s     // V0 += V1 * V2 (fused multiply-add)
    
    add x10, x10, #4
    b .Ldot_simd_loop
    
.Ldot_scalar_loop:
    // Handle remaining elements (if dimension % 4 != 0)
    cmp x10, x21
    bge .Ldot_reduce
    
    add x11, x19, x10, lsl #2    // Load single float from vector_a
    ldr s1, [x11]
    add x12, x20, x10, lsl #2    // Load single float from vector_b
    ldr s2, [x12]
    fmul s1, s1, s2              // S1 = vector_a[i] * vector_b[i]
    fadd s0, s0, s1              // S0 += S1
    
    add x10, x10, #1
    b .Ldot_scalar_loop
    
.Ldot_reduce:
    // Reduce 4 floats in V0 to a single sum using horizontal add
    // V0 = [a, b, c, d]
    // We need: a + b + c + d
    faddp v1.4s, v0.4s, v0.4s    // V1 = [a+b, c+d, a+b, c+d]
    faddp v0.4s, v1.4s, v1.4s    // V0 = [a+b+c+d, a+b+c+d, ...]
    
    // Result is in S0 (first lane of V0)
    
.Ldot_done:
    // Epilogue
    ldp x21, x22, [sp, #32]      // Restore callee-saved registers
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret


// ============================================
// Function: cosine_similarity_asm
// Calculate cosine similarity between two embedding vectors
// cosine_similarity = dot(a,b) / (||a|| * ||b||)
// Parameters:
//   X0 = float* vector_a
//   X1 = float* vector_b
//   X2 = int dimension
// Returns:
//   S0 = cosine similarity (float)
// ============================================
    .global _cosine_similarity_asm
_cosine_similarity_asm:
    // Prologue
    stp x29, x30, [sp, #-64]!    // Save frame pointer and link register
    mov x29, sp
    stp x19, x20, [sp, #16]      // Save callee-saved registers
    stp x21, x22, [sp, #32]
    str d8, [sp, #48]            // Save callee-saved NEON register
    
    // Save parameters to callee-saved registers
    mov x19, x0                  // vector_a
    mov x20, x1                  // vector_b
    mov x21, x2                  // dimension
    
    // Step 1: Calculate dot product
    mov x0, x19                  // vector_a
    mov x1, x20                  // vector_b
    mov x2, x21                  // dimension
    bl _dot_product_asm
    fmov s8, s0                  // Save dot_product in S8 (callee-saved)
    
    // Step 2: Calculate ||vector_a|| (L2 norm)
    mov x0, x19                  // vector_a
    mov x1, x21                  // dimension
    bl _vector_norm_asm
    fmov s9, s0                  // Save norm_a in S9
    
    // Step 3: Calculate ||vector_b|| (L2 norm)
    mov x0, x20                  // vector_b
    mov x1, x21                  // dimension
    bl _vector_norm_asm
    fmov s10, s0                 // Save norm_b in S10
    
    // Step 4: Calculate cosine = dot / (norm_a * norm_b)
    fmov s0, s8                  // S0 = dot_product
    fmov s1, s9                  // S1 = norm_a
    fmul s1, s1, s10             // S1 = norm_a * norm_b
    
    // Avoid division by zero
    adrp x9, float_zero@PAGE
    add x9, x9, float_zero@PAGEOFF
    ldr s2, [x9]
    fcmp s1, s2
    beq .Lcos_return_zero        // If norm == 0, return 0
    
    fdiv s0, s0, s1              // S0 = dot / (norm_a * norm_b)
    b .Lcos_done
    
.Lcos_return_zero:
    fmov s0, wzr                 // Return 0.0
    
.Lcos_done:
    ldr d8, [sp, #48]            // Restore callee-saved NEON register
    ldp x21, x22, [sp, #32]      // Restore callee-saved registers
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret


// ============================================
// Function: vector_norm_asm
// Calculate L2 norm (Euclidean norm) of a vector
// ||v|| = sqrt(sum(v[i]^2))
// Parameters:
//   X0 = float* vector
//   X1 = int dimension
// Returns:
//   S0 = norm (float)
// ============================================
    .global _vector_norm_asm
_vector_norm_asm:
    // Prologue
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    
    // Save parameters
    mov x19, x0                  // vector
    mov x20, x1                  // dimension
    
    // Initialize sum of squares to zero
    eor v0.16b, v0.16b, v0.16b
    
    // Check dimension
    cbz x20, .Lnorm_done
    
    mov x10, #0                  // Index counter
    
.Lnorm_simd_loop:
    cmp x10, x20
    bge .Lnorm_reduce
    
    // Check if we can process 4 floats
    sub x11, x20, x10
    cmp x11, #4
    blt .Lnorm_single
    
    // Process 4 floats: compute squares and sum
    add x11, x19, x10, lsl #2
    ld1 {v1.4s}, [x11]           // V1 = vector[i:i+4]
    fmla v0.4s, v1.4s, v1.4s     // V0 += V1 * V1 (squares)
    
    add x10, x10, #4
    b .Lnorm_simd_loop
    
.Lnorm_single:
    // Process single float
    cmp x10, x20
    bge .Lnorm_reduce
    add x11, x19, x10, lsl #2
    ldr s1, [x11]
    fmul s1, s1, s1              // S1 = vector[i]^2
    fadd s0, s0, s1              // S0 += square
    
    add x10, x10, #1
    b .Lnorm_simd_loop
    
.Lnorm_reduce:
    // Reduce 4 floats to sum (horizontal add)
    faddp v1.4s, v0.4s, v0.4s    // V1 = [a+b, c+d, ...]
    faddp v0.4s, v1.4s, v1.4s    // V0 = [a+b+c+d, ...]
    
    // Take square root
    fsqrt s0, s0                 // S0 = sqrt(sum of squares)
    
.Lnorm_done:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret


// ============================================
// Function: normalize_vector_asm
// Normalize a vector to unit length (in-place)
// v_normalized = v / ||v||
// Parameters:
//   X0 = float* vector (modified in-place)
//   X1 = int dimension
// Returns:
//   Nothing (vector is modified in-place)
// ============================================
    .global _normalize_vector_asm
_normalize_vector_asm:
    // Prologue
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    
    // Save parameters
    mov x19, x0                  // vector
    mov x20, x1                  // dimension
    
    // Calculate norm inline (same logic as vector_norm_asm)
    eor v0.16b, v0.16b, v0.16b
    
    // Check dimension
    cbz x20, .Lnormalize_done
    
    mov x10, #0                  // Index counter
    
.Lnormalize_norm_loop:
    cmp x10, x20
    bge .Lnormalize_norm_done
    
    // Check if we can process 4 floats
    sub x11, x20, x10
    cmp x11, #4
    blt .Lnormalize_norm_single
    
    // Process 4 floats: compute squares and sum
    add x11, x19, x10, lsl #2
    ld1 {v1.4s}, [x11]
    fmla v0.4s, v1.4s, v1.4s
    
    add x10, x10, #4
    b .Lnormalize_norm_loop
    
.Lnormalize_norm_single:
    // Process single float
    cmp x10, x20
    bge .Lnormalize_norm_done
    add x11, x19, x10, lsl #2
    ldr s1, [x11]
    fmul s1, s1, s1
    fadd s0, s0, s1
    
    add x10, x10, #1
    b .Lnormalize_norm_loop
    
.Lnormalize_norm_done:
    // Reduce 4 floats to sum
    faddp v1.4s, v0.4s, v0.4s
    faddp v0.4s, v1.4s, v1.4s
    
    // Take square root
    fsqrt s0, s0                 // S0 = norm
    
    // Check if norm is zero
    adrp x9, float_zero@PAGE
    add x9, x9, float_zero@PAGEOFF
    ldr s1, [x9]
    fcmp s0, s1
    beq .Lnormalize_done         // If norm == 0, don't divide
    
    // Broadcast norm to all 4 lanes for NEON division
    dup v2.4s, v0.s[0]           // V2 = [norm, norm, norm, norm]
    
    // Divide each element by norm
    mov x10, #0
    
.Lnormalize_div_loop:
    cmp x10, x20
    bge .Lnormalize_done
    
    // Check if we can process 4 floats
    sub x11, x20, x10
    cmp x11, #4
    blt .Lnormalize_div_single
    
    // Load 4 floats and divide by norm
    add x11, x19, x10, lsl #2
    ld1 {v1.4s}, [x11]
    fdiv v1.4s, v1.4s, v2.4s     // V1 = vector[i:i+4] / norm
    st1 {v1.4s}, [x11]
    
    add x10, x10, #4
    b .Lnormalize_div_loop
    
.Lnormalize_div_single:
    cmp x10, x20
    bge .Lnormalize_done
    
    add x11, x19, x10, lsl #2
    ldr s1, [x11]
    fdiv s1, s1, s0              // Single float division
    str s1, [x11]
    add x10, x10, #1
    b .Lnormalize_div_single
    
.Lnormalize_done:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret


// ============================================
// Function: add_vectors_asm
// Add two vectors element-wise: result = a + b
// Parameters:
//   X0 = float* vector_a
//   X1 = float* vector_b
//   X2 = float* result (output)
//   X3 = int dimension
// Returns:
//   Nothing (result written to memory)
// ============================================
    .global _add_vectors_asm
_add_vectors_asm:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    
    // Save parameters
    mov x19, x0                  // vector_a
    mov x20, x1                  // vector_b
    mov x21, x2                  // result
    mov x22, x3                  // dimension
    
    cbz x22, .Ladd_done
    
    mov x10, #0
    
.Ladd_loop:
    cmp x10, x22
    bge .Ladd_done
    
    // Check if we can process 4 floats
    sub x23, x22, x10
    cmp x23, #4
    blt .Ladd_single
    
    // Load 4 floats from both vectors
    add x11, x19, x10, lsl #2
    ld1 {v0.4s}, [x11]           // vector_a[i:i+4]
    add x12, x20, x10, lsl #2
    ld1 {v1.4s}, [x12]           // vector_b[i:i+4]
    fadd v0.4s, v0.4s, v1.4s     // V0 = a + b
    add x13, x21, x10, lsl #2
    st1 {v0.4s}, [x13]           // result[i:i+4] = a + b
    
    add x10, x10, #4
    b .Ladd_loop
    
.Ladd_single:
    cmp x10, x22
    bge .Ladd_done
    
    add x11, x19, x10, lsl #2
    ldr s0, [x11]
    add x12, x20, x10, lsl #2
    ldr s1, [x12]
    fadd s0, s0, s1
    add x13, x21, x10, lsl #2
    str s0, [x13]
    
    add x10, x10, #1
    b .Ladd_single
    
.Ladd_done:
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

