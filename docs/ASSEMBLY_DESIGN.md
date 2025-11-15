# Assembly Implementation Design: Improved Hash-Based Embedding

**Version**: 1.0.1  
**Date**: 2025-01-14  
**Author**: FastEmbed Development Team

---

## Overview

This document specifies the x86-64 assembly implementation design for the improved hash-based embedding algorithm. The implementation uses SIMD instructions for performance optimization while maintaining ABI compliance for Windows, Linux, and macOS.

---

## Function Signature

### C Interface

```c
int generate_embedding_asm(
    const char *text,      // Input text (UTF-8, null-terminated)
    float *output,         // Output array (pre-allocated, size >= dimension)
    int dimension          // Embedding dimension (128, 256, 512, 768, 1024, 2048)
);
```

### Assembly Entry Point

```assembly
global generate_embedding_asm
generate_embedding_asm:
    ; Function implementation
```

---

## ABI Compliance

### System V ABI (Linux/macOS)

**Calling Convention**:

- **Parameter 1** (text): `RDI`
- **Parameter 2** (output): `RSI`
- **Parameter 3** (dimension): `EDX`
- **Return value**: `RAX` (0 = success, -1 = error)

**Callee-Saved Registers** (must preserve):

- `RBX`, `RBP`, `R12`, `R13`, `R14`, `R15`

**Caller-Saved Registers** (can use freely):

- `RAX`, `RCX`, `RDX`, `RDI`, `RSI`, `R8`, `R9`, `R10`, `R11`

**Stack Alignment**: 16-byte aligned (required for SIMD)

### Microsoft x64 ABI (Windows)

**Calling Convention**:

- **Parameter 1** (text): `RCX`
- **Parameter 2** (output): `RDX`
- **Parameter 3** (dimension): `R8D`
- **Return value**: `RAX` (0 = success, -1 = error)

**Shadow Space**: 32 bytes (must allocate)

**Callee-Saved Registers** (must preserve):

- `RBX`, `RBP`, `RDI`, `RSI`, `R12`, `R13`, `R14`, `R15`, `XMM6-XMM15`

**Stack Alignment**: 16-byte aligned (required for SIMD)

### ABI Abstraction Macros

```assembly
%ifdef WIN64
    %define PARAM1 rcx      ; text
    %define PARAM2 rdx      ; output
    %define PARAM3 r8d      ; dimension
    %define SHADOW_SPACE 32
%else
    %define PARAM1 rdi      ; text
    %define PARAM2 rsi      ; output
    %define PARAM3 edx      ; dimension
    %define SHADOW_SPACE 0
%endif
```

---

## Register Usage Plan

### Callee-Saved Registers (Preserved)

```
R12: text pointer (saved)
R13: output pointer (saved)
R14: text length (saved)
R15: dimension counter (saved)
RBX: temporary (if needed)
RBP: frame pointer (if needed)
```

### Caller-Saved Registers (Working)

```
RAX: dimension index (loop counter)
RCX: character value, temporary
RDX: hash values, temporary
R8:  hash1 (positional)
R9:  hash2 (secondary)
R10: combined hash, temporary
R11: position weight, temporary
```

### SIMD Registers (XMM)

```
XMM0: Sin input/output, temporary
XMM1: Constants (2π, SCALE), temporary
XMM2: Temporary calculations
XMM3: Temporary calculations
XMM4-XMM7: Available for parallel processing
```

---

## Stack Layout

### Function Prologue

```assembly
push rbp
mov rbp, rsp
sub rsp, SHADOW_SPACE + LOCAL_VARS

; Save callee-saved registers
push r12
push r13
push r14
push r15
```

### Local Variables (on stack)

```
[rbp - 8]:  text_length (8 bytes)
[rbp - 16]: dimension (4 bytes, padding)
[rbp - 20]: SCALE constant (4 bytes)
[rbp - 24]: 2π constant (4 bytes)
```

### Function Epilogue

```assembly
; Restore callee-saved registers
pop r15
pop r14
pop r13
pop r12

; Restore stack
add rsp, SHADOW_SPACE + LOCAL_VARS
pop rbp
ret
```

---

## Algorithm Implementation

### Step 1: Input Validation

```assembly
; Check text pointer
test PARAM1, PARAM1
jz .error

; Check output pointer
test PARAM2, PARAM2
jz .error

; Check dimension
cmp PARAM3, 128
jl .error
cmp PARAM3, 2048
jg .error
; Check if dimension is in valid set: 128, 256, 512, 768, 1024, 2048
; (Use lookup table or bit mask)
```

### Step 2: Calculate Text Length

```assembly
mov r12, PARAM1        ; text pointer
xor r14, r14           ; text_length counter

.text_length_loop:
    cmp byte [r12 + r14], 0
    je .text_length_done
    inc r14
    jmp .text_length_loop

.text_length_done:
    test r14, r14      ; Check if empty
    jz .error
    cmp r14, 8192      ; MAX_TEXT_LENGTH
    jg .error
```

### Step 3: Embedding Generation Loop

```assembly
mov r13, PARAM2        ; output pointer
mov r15, PARAM3        ; dimension
xor rax, rax           ; dimension index (i)

.embedding_loop:
    cmp rax, r15       ; Check if i < dimension
    jge .embedding_done
    
    ; Step 3.1: Generate Positional Hash (hash1)
    mov r8, rax        ; seed = i
    mov r12, PARAM1    ; text pointer
    xor r11, r11       ; position index (j)
    
.hash1_loop:
    cmp r11, r14       ; Check if j < text_length
    jge .hash1_done
    
    ; Load character
    movzx rcx, byte [r12 + r11]
    test rcx, rcx      ; Check for null terminator
    jz .hash1_done
    
    ; Calculate position weight: (j + 1)
    mov rdx, r11
    inc rdx            ; position_weight = j + 1
    
    ; Hash: hash1 = hash1 * 31 + char * position_weight
    mov r10, r8        ; Save current hash
    shl r10, 5         ; hash1 * 32
    sub r10, r8        ; hash1 * 31 = hash1 * 32 - hash1
    mov r8, r10        ; hash1 = hash1 * 31
    mov r10, rcx       ; char
    imul r10, rdx      ; char * position_weight
    add r8, r10        ; hash1 += char * position_weight
    
    inc r11
    jmp .hash1_loop
    
.hash1_done:
    ; r8 now contains hash1
    
    ; Step 3.2: Generate Secondary Hash (hash2)
    mov r9, rax        ; seed = i
    imul r9, 37        ; seed = i * 37
    mov r12, PARAM1    ; text pointer
    xor r11, r11       ; position index (j)
    
.hash2_loop:
    cmp r11, r14       ; Check if j < text_length
    jge .hash2_done
    
    ; Load character
    movzx rcx, byte [r12 + r11]
    test rcx, rcx      ; Check for null terminator
    jz .hash2_done
    
    ; Calculate position weight: (j + 1)
    mov rdx, r11
    inc rdx            ; position_weight = j + 1
    
    ; Hash: hash2 = hash2 * 31 + char * position_weight
    mov r10, r9        ; Save current hash
    shl r10, 5         ; hash2 * 32
    sub r10, r9        ; hash2 * 31 = hash2 * 32 - hash2
    mov r9, r10        ; hash2 = hash2 * 31
    mov r10, rcx       ; char
    imul r10, rdx      ; char * position_weight
    add r9, r10        ; hash2 += char * position_weight
    
    inc r11
    jmp .hash2_loop
    
.hash2_done:
    ; r9 now contains hash2
    
    ; Step 3.3: Combine Hashes
    mov r10, r9        ; hash2
    shl r10, 16        ; hash2 << 16
    xor r10, r8        ; combined = hash1 ^ (hash2 << 16)
    
    ; Step 3.4: Normalize with Sin
    ; combined is in r10 (uint64)
    ; We need: sin((combined % SCALE) / SCALE * 2π)
    
    ; Use low 32 bits for modulo
    mov rdx, r10
    and rdx, 0xFFFFFFFF  ; combined % (2^32)
    
    ; Convert to float
    cvtsi2ss xmm0, rdx    ; xmm0 = combined (as float)
    
    ; Divide by SCALE (2^31)
    mov rdx, 2147483648   ; SCALE = 2^31
    cvtsi2ss xmm1, rdx
    divss xmm0, xmm1      ; xmm0 = (combined % SCALE) / SCALE
    
    ; Multiply by 2π
    movss xmm1, [rel two_pi]  ; Load 2π constant
    mulss xmm0, xmm1          ; xmm0 = (combined % SCALE) / SCALE * 2π
    
    ; Calculate sin(xmm0)
    ; Use SSE4 sinps or approximation
    call sin_approx_asm       ; xmm0 = sin(xmm0)
    
    ; Step 3.5: Store in output array
    movss [r13 + rax*4], xmm0  ; output[i] = sin_value
    
    ; Next iteration
    inc rax
    jmp .embedding_loop

.embedding_done:
    ; Success
    xor rax, rax
    jmp .done

.error:
    mov rax, -1

.done:
    ; Restore registers and return
    pop r15
    pop r14
    pop r13
    pop r12
    add rsp, SHADOW_SPACE + LOCAL_VARS
    pop rbp
    ret
```

---

## SIMD Optimization Strategy

### Sin Approximation

**Option 1: SSE4 `sinps`** (if available):

```assembly
sinps xmm0, xmm0  ; Direct SSE4 sin instruction
```

**Option 2: Polynomial Approximation** (fallback):

```assembly
; Taylor series: sin(x) ≈ x - x³/6 + x⁵/120 - x⁷/5040
; Optimized for [-π, π] range
```

**Option 3: Lookup Table** (fastest, less accurate):

```assembly
; Pre-computed sin table for common values
; Interpolate for intermediate values
```

### Parallel Processing

For multiple dimensions, process 4 dimensions in parallel:

```assembly
; Process 4 dimensions simultaneously using XMM registers
; XMM0, XMM1, XMM2, XMM3 for 4 different hash calculations
```

---

## Constants

### Data Section

```assembly
section .data
    two_pi:     dd 6.283185307179586  ; 2π
    scale:      dd 2147483648.0       ; 2^31
    one:        dd 1.0
    minus_one:  dd -1.0
```

### Read-Only Data

```assembly
section .rodata
    valid_dimensions: dq 128, 256, 512, 768, 1024, 2048, 0
```

---

## Error Handling

### Input Validation Errors

```assembly
.error_null_text:
    mov rax, -1
    jmp .done

.error_null_output:
    mov rax, -1
    jmp .done

.error_invalid_dimension:
    mov rax, -1
    jmp .done

.error_empty_text:
    mov rax, -1
    jmp .done

.error_text_too_long:
    mov rax, -1
    jmp .done
```

---

## Performance Optimizations

### Loop Unrolling

For small dimensions (128, 256), unroll loop:

```assembly
; Process 4 dimensions per iteration
; Reduces loop overhead
```

### Branch Prediction

Use likely/unlikely hints:

```assembly
; Mark common path as likely
; Optimize for dimension = 128 (default)
```

### Cache Optimization

- Align data structures to cache lines
- Prefetch next text characters
- Minimize memory accesses

---

## Testing Strategy

### Unit Tests

1. **ABI Compliance**: Test on Windows, Linux, macOS
2. **Stack Alignment**: Verify 16-byte alignment
3. **Register Preservation**: Verify callee-saved registers
4. **Error Handling**: Test all error paths

### Integration Tests

1. **Determinism**: Same input → same output
2. **Range**: All values in `[-1, 1]`
3. **Performance**: Measure execution time
4. **Quality**: Verify discrimination improvement

---

## References

- `ALGORITHM_MATH.md`: Mathematical foundation
- `ALGORITHM_SPECIFICATION.md`: Algorithm specification
- System V ABI documentation
- Microsoft x64 ABI documentation
- Intel x86-64 Instruction Set Reference

---

**End of Design Document**
