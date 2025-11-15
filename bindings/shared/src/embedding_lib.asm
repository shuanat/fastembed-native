; Embedding Library for Vector Search (Assembly x86-64)
; Provides SIMD-optimized functions for embedding operations
;
; To compile:
;   nasm -f win64 embedding_lib.asm -o embedding_lib.obj (Windows)
;   nasm -f elf64 embedding_lib.asm -o embedding_lib.o (Linux)
;
; To link:
;   gcc embedding_lib.obj embedding_lib_c.c -o embedding_lib.dll (Windows DLL)
;   gcc embedding_lib.o embedding_lib_c.c -o embedding_lib.so (Linux shared)

%ifidn __OUTPUT_FORMAT__,elf64
    ; Linux System V ABI
    %define PARAM1 rdi
    %define PARAM2 rsi
    %define PARAM3 rdx
    %define PARAM4 rcx
    %define PARAM5 r8
    %define PARAM6 r9
    %define SHADOW_SPACE 0
%elifidn __OUTPUT_FORMAT__,win64
    ; Windows x64 calling convention
    %define PARAM1 rcx
    %define PARAM2 rdx
    %define PARAM3 r8
    %define PARAM4 r9
    %define PARAM5 rsp+32
    %define PARAM6 rsp+40
    %define SHADOW_SPACE 32
%elifidn __OUTPUT_FORMAT__,macho64
    ; macOS System V ABI (same as Linux)
    %define PARAM1 rdi
    %define PARAM2 rsi
    %define PARAM3 rdx
    %define PARAM4 rcx
    %define PARAM5 r8
    %define PARAM6 r9
    %define SHADOW_SPACE 0
%else
    %error "Unsupported output format. Supported: elf64 (Linux), win64 (Windows), macho64 (macOS)"
%endif

section .data
    align 16
    ; Constants
    float_one: dd 1.0
    float_zero: dd 0.0
    pi_constant: dd 3.14159265358979323846
    
    ; Embedding dimension (768 for nomic-embed-text)
    embedding_dim: dd 768
    
section .bss
    align 16
    ; Temporary storage for calculations
    temp_vector: resd 768   ; 768 floats = 3072 bytes

section .text
default rel    ; Use RIP-relative addressing for PIC

; ============================================
; Function: dot_product
; Calculate dot product of two embedding vectors
; Parameters (Windows x64 calling convention):
;   RCX = float* vector_a (pointer to first vector)
;   RDX = float* vector_b (pointer to second vector)
;   R8  = int dimension (number of elements, typically 768)
; Returns:
;   XMM0 = dot product (float)
; ============================================
global dot_product_asm
dot_product_asm:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    ; Save callee-saved registers (r12 must be saved in System V ABI)
    push r12
    
    ; Parameters already in correct registers:
    ; System V: rdi=vector_a, rsi=vector_b, rdx=dimension
    ; Windows: rcx=vector_a, rdx=vector_b, r8=dimension
    ; Save to consistent registers for both platforms
    mov r10, PARAM1     ; vector_a
    mov r11, PARAM2     ; vector_b
    mov r12, PARAM3     ; dimension
    
    ; Initialize accumulator to zero
    xorps xmm0, xmm0    ; xmm0 = 0.0
    
    ; Check if dimension is zero
    test r12, r12
    jz .done
    
    ; Calculate how many 4-float blocks we can process with SIMD
    mov r9, r12         ; r9 = dimension
    and r9, 0xFFFFFFFFFFFFFFFC  ; r9 = dimension - (dimension % 4) [align to 4]
    
    ; Process 4 floats at a time with SSE
    xor rax, rax        ; rax = index counter
    
.simd_loop:
    cmp rax, r9
    jge .scalar_loop
    
    ; Load 4 floats from vector_a
    movups xmm1, [r10 + rax*4]   ; xmm1 = vector_a[i:i+4]
    
    ; Load 4 floats from vector_b
    movups xmm2, [r11 + rax*4]   ; xmm2 = vector_b[i:i+4]
    
    ; Multiply and add
    mulps xmm1, xmm2             ; xmm1 = vector_a * vector_b (element-wise)
    addps xmm0, xmm1             ; xmm0 += xmm1
    
    add rax, 4
    jmp .simd_loop
    
.scalar_loop:
    ; Handle remaining elements (if dimension % 4 != 0)
    cmp rax, r12
    jge .reduce
    
    movss xmm1, [r10 + rax*4]    ; Load single float from vector_a
    movss xmm2, [r11 + rax*4]    ; Load single float from vector_b
    mulss xmm1, xmm2             ; xmm1 = vector_a[i] * vector_b[i]
    addss xmm0, xmm1             ; xmm0 += xmm1
    
    inc rax
    jmp .scalar_loop
    
.reduce:
    ; Reduce 4 floats in xmm0 to a single sum using horizontal add
    ; xmm0 = [a, b, c, d]
    ; We need: a + b + c + d
    movaps xmm1, xmm0
    shufps xmm1, xmm0, 0x1B      ; [d, c, b, a]
    addps xmm0, xmm1             ; [a+d, b+c, b+c, a+d]
    
    movaps xmm1, xmm0
    shufps xmm1, xmm0, 0xB1      ; [b+c, a+d, a+d, b+c]
    addps xmm0, xmm1             ; [a+b+c+d, a+b+c+d, a+b+c+d, a+b+c+d]
    
    ; Extract first element (they're all the same now)
    ; Result is in xmm0[0]
    
.done:
    ; Epilogue
    pop r12              ; Restore callee-saved register
    add rsp, SHADOW_SPACE
    pop rbp
    ret


; ============================================
; Function: cosine_similarity_asm
; Calculate cosine similarity between two embedding vectors
; cosine_similarity = dot(a,b) / (||a|| * ||b||)
; Parameters:
;   RCX = float* vector_a
;   RDX = float* vector_b
;   R8  = int dimension
; Returns:
;   XMM0 = cosine similarity (float)
; ============================================
global cosine_similarity_asm
cosine_similarity_asm:
    ; Prologue
    push rbp           ; rsp -= 8
    mov rbp, rsp
    
    ; Save callee-saved registers (System V ABI requires r12, r13, r14, r15, rbx)
    push r12           ; rsp -= 8  (total: 16)
    push r13           ; rsp -= 8  (total: 24)
    push r14           ; rsp -= 8  (total: 32) - save r14 for parameters
    
    ; Stack layout after pushes:
    ; rsp+0:  r14 (saved, will store dimension)
    ; rsp+8:  r13 (saved, will store vector_b)
    ; rsp+16: r12 (saved, will store vector_a)
    ; rsp+24: rbp (saved)
    ; rsp+32: return address
    
    ; Allocate space for local variables (dot_product, norm_a, norm_b = 3 floats = 12 bytes, round to 16)
    ; After 4 pushes: 32 bytes (32 mod 16 = 0, already aligned!)
    ; Add 16 bytes for local variables
    sub rsp, 16        ; Space for: dot_product (rsp+0), norm_a (rsp+4), norm_b (rsp+8)
    
    ; Save parameters to callee-saved registers and stack
    ; Parameters: PARAM1=vector_a, PARAM2=vector_b, PARAM3=dimension
    mov r12, PARAM1    ; vector_a (callee-saved, safe)
    mov r13, PARAM2    ; vector_b (callee-saved, safe)
    mov r14, PARAM3    ; dimension (callee-saved, safe)
    
    ; Step 1: Calculate dot product
    ; Stack is now aligned: after 4 pushes (32 bytes, aligned) + 16 bytes locals = 48 total
    ; Before call, rsp must be aligned: 48 mod 16 = 0 ✓
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, r12       ; vector_a
    mov rsi, r13       ; vector_b
    mov rdx, r14       ; dimension
%else
    mov rcx, r12       ; Windows: vector_a
    mov rdx, r13       ; Windows: vector_b
    mov r8, r14        ; Windows: dimension
%endif
    call dot_product_asm
    movss [rsp + 0], xmm0   ; Save dot_product
    
    ; Step 2: Calculate ||vector_a|| (L2 norm)
    ; Stack is still aligned after call (call preserved alignment)
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, r12       ; vector_a
    mov rsi, r14       ; dimension
%else
    mov rcx, r12       ; Windows: vector_a
    mov rdx, r14       ; Windows: dimension
%endif
    call vector_norm_asm
    movss [rsp + 4], xmm0   ; Save norm_a
    
    ; Step 3: Calculate ||vector_b|| (L2 norm)
    ; Stack is still aligned
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, r13       ; vector_b
    mov rsi, r14       ; dimension
%else
    mov rcx, r13       ; Windows: vector_b
    mov rdx, r14       ; Windows: dimension
%endif
    call vector_norm_asm
    movss [rsp + 8], xmm0   ; Save norm_b
    
    ; Step 4: Calculate cosine = dot / (norm_a * norm_b)
    movss xmm0, [rsp + 0]   ; xmm0 = dot_product
    movss xmm1, [rsp + 4]   ; xmm1 = norm_a
    mulss xmm1, [rsp + 8]   ; xmm1 = norm_a * norm_b
    
    ; Avoid division by zero
    movss xmm2, xmm1
    comiss xmm2, [rel float_zero]
    je .return_zero           ; If norm == 0, return 0
    
    divss xmm0, xmm1          ; xmm0 = dot / (norm_a * norm_b)
    jmp .done
    
.return_zero:
    xorps xmm0, xmm0          ; Return 0
    
.done:
    add rsp, 16         ; Free local variables space
    pop r14              ; Restore callee-saved registers
    pop r13
    pop r12
    pop rbp
    ret


; ============================================
; Function: vector_norm_asm
; Calculate L2 norm (Euclidean norm) of a vector
; ||v|| = sqrt(sum(v[i]^2))
; Parameters:
;   RCX = float* vector
;   R8  = int dimension
; Returns:
;   XMM0 = norm (float)
; ============================================
global vector_norm_asm
vector_norm_asm:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    ; Save callee-saved registers
    push r12
    
    ; Save parameters to consistent registers
    mov r10, PARAM1    ; vector
    mov r12, PARAM2   ; dimension
    
    ; Initialize sum of squares to zero
    xorps xmm0, xmm0
    
    ; Check dimension
    test r12, r12
    jz .done
    
    xor rax, rax              ; Index counter
    
.simd_loop:
    cmp rax, r12
    jge .reduce
    
    ; Check if we can process 4 floats
    mov r11, r12
    sub r11, rax
    cmp r11, 4
    jl .single
    
    ; Process 4 floats: compute squares and sum
    movups xmm1, [r10 + rax*4]
    mulps xmm1, xmm1          ; xmm1 = vector[i:i+4]^2
    addps xmm0, xmm1          ; xmm0 += squares
    
    add rax, 4
    jmp .simd_loop
    
.single:
    ; Process single float
    cmp rax, r12
    jge .reduce
    movss xmm1, [r10 + rax*4]
    mulss xmm1, xmm1          ; xmm1 = vector[i]^2
    addss xmm0, xmm1          ; xmm0 += square
    
    inc rax
    jmp .simd_loop
    
.reduce:
    ; Reduce 4 floats to sum (same as dot_product)
    movaps xmm1, xmm0
    haddps xmm1, xmm0        ; Horizontal add: [a+b, c+d, a+b, c+d]
    haddps xmm1, xmm1        ; Horizontal add: [a+b+c+d, a+b+c+d, a+b+c+d, a+b+c+d]
    movaps xmm0, xmm1        ; Copy to xmm0
    
    ; Take square root
    sqrtss xmm0, xmm0        ; xmm0 = sqrt(sum of squares)
    
.done:
    pop r12              ; Restore callee-saved register
    add rsp, SHADOW_SPACE
    pop rbp
    ret


; ============================================
; Function: normalize_vector_asm
; Normalize a vector to unit length (in-place)
; v_normalized = v / ||v||
; Parameters:
;   RCX = float* vector (modified in-place)
;   R8  = int dimension
; Returns:
;   Nothing (vector is modified in-place)
; ============================================
global normalize_vector_asm
normalize_vector_asm:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    ; Save callee-saved registers
    push r12
    
    ; Save parameters to consistent registers
    mov r10, PARAM1    ; vector
    mov r12, PARAM2    ; dimension
    
    ; Calculate norm inline (same logic as vector_norm_asm)
    ; Initialize sum of squares to zero
    xorps xmm0, xmm0
    xorps xmm1, xmm1
    
    ; Check dimension
    test r12, r12
    jz .done
    
    xor rax, rax              ; Index counter
    
.norm_loop:
    cmp rax, r12
    jge .norm_done
    
    ; Check if we can process 4 floats
    mov r11, r12
    sub r11, rax
    cmp r11, 4
    jl .norm_single
    
    ; Process 4 floats: compute squares and sum
    movups xmm1, [r10 + rax*4]
    mulps xmm1, xmm1          ; xmm1 = vector[i:i+4]^2
    addps xmm0, xmm1          ; xmm0 += squares
    
    add rax, 4
    jmp .norm_loop
    
.norm_single:
    ; Process single float
    cmp rax, r12
    jge .norm_done
    movss xmm1, [r10 + rax*4]
    mulss xmm1, xmm1          ; xmm1 = vector[i]^2
    addss xmm0, xmm1          ; xmm0 += square
    
    inc rax
    jmp .norm_loop
    
.norm_done:
    ; Reduce 4 floats to sum
    movaps xmm1, xmm0
    haddps xmm1, xmm0        ; Horizontal add
    haddps xmm1, xmm1        ; Horizontal add again
    movaps xmm0, xmm1        ; Copy to xmm0
    
    ; Take square root
    sqrtss xmm0, xmm0        ; xmm0 = sqrt(sum of squares)
    
    ; Check if norm is zero
    comiss xmm0, [rel float_zero]
    je .done                  ; If norm == 0, don't divide
    
    ; Broadcast norm to all 4 slots for SIMD division
    shufps xmm0, xmm0, 0x00   ; [norm, norm, norm, norm]
    
    ; Divide each element by norm
    ; r10 and r12 are already restored above
    xor rax, rax
    
.normalize_loop:
    cmp rax, r12
    jge .handle_remaining
    
    ; Check if we can process 4 floats
    mov r11, r12
    sub r11, rax
    cmp r11, 4
    jl .handle_remaining
    
    ; Load 4 floats and divide by norm
    movups xmm1, [r10 + rax*4]
    divps xmm1, xmm0          ; xmm1 = vector[i:i+4] / norm
    movups [r10 + rax*4], xmm1
    
    add rax, 4
    jmp .normalize_loop
    
    ; Handle remaining elements
.handle_remaining:
    cmp rax, r12
    jge .done
    
    ; Process remaining singles
.single_loop:
    movss xmm1, [r10 + rax*4]
    divss xmm1, xmm0          ; Single float division
    movss [r10 + rax*4], xmm1
    inc rax
    cmp rax, r12
    jl .single_loop
    
.done:
    ; Restore callee-saved registers
    pop r12
    add rsp, SHADOW_SPACE
    pop rbp
    ret


; ============================================
; Function: add_vectors_asm
; Add two vectors element-wise: result = a + b
; Parameters:
;   RCX = float* vector_a
;   RDX = float* vector_b
;   R8  = float* result (output)
;   R9  = int dimension
; Returns:
;   Nothing (result written to memory)
; ============================================
global add_vectors_asm
add_vectors_asm:
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    ; Save callee-saved registers (r12, r13, r14 are callee-saved in System V ABI)
    push r12
    push r13
    push r14
    
    ; Save parameters to consistent registers
    ; Parameters: vector_a, vector_b, result, dimension
    mov r10, PARAM1    ; vector_a
    mov r11, PARAM2    ; vector_b
    mov r13, PARAM3    ; result
    mov r12, PARAM4    ; dimension
    
    test r12, r12
    jz .done
    
    xor rax, rax
    
.add_loop:
    cmp rax, r12
    jge .handle_remaining
    
    ; Check if we can process 4 floats
    mov r14, r12
    sub r14, rax
    cmp r14, 4
    jl .handle_remaining
    
    ; Load 4 floats from both vectors
    movups xmm0, [r10 + rax*4]   ; vector_a[i:i+4]
    movups xmm1, [r11 + rax*4]   ; vector_b[i:i+4]
    addps xmm0, xmm1              ; xmm0 = a + b
    movups [r13 + rax*4], xmm0   ; result[i:i+4] = a + b
    
    add rax, 4
    jmp .add_loop
    
    ; Handle remaining elements
.handle_remaining:
    cmp rax, r12
    jge .done
    
.single_loop:
    movss xmm0, [r10 + rax*4]
    movss xmm1, [r11 + rax*4]
    addss xmm0, xmm1
    movss [r13 + rax*4], xmm0
    
    inc rax
    cmp rax, r12
    jl .single_loop
    
.done:
    pop r14              ; Restore callee-saved registers
    pop r13
    pop r12
    add rsp, SHADOW_SPACE
    pop rbp
    ret

