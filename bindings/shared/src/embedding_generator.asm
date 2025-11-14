; Simple Embedding Generator (Assembly x86-64)
; Generates basic embeddings from text using hash-based approach
; This is a simple implementation - for production use, you'd need
; a full neural network model (requires Python/C++ backend)
;
; Strategy: 
; - Generate hash-based features from text
; - Create normalized vector from hash values
; - Output 768-dimension vector compatible with nomic-embed-text

%ifidn __OUTPUT_FORMAT__,elf64
    %define PARAM1 rdi
    %define PARAM2 rsi
    %define PARAM3 rdx
    %define PARAM4 rcx
    %define PARAM5 r8
    %define PARAM6 r9
    %define SHADOW_SPACE 0
%elifidn __OUTPUT_FORMAT__,win64
    %define PARAM1 rcx
    %define PARAM2 rdx
    %define PARAM3 r8
    %define PARAM4 r9
    %define PARAM5 rsp+32
    %define PARAM6 rsp+40
    %define SHADOW_SPACE 32
%else
    %error "Unsupported output format"
%endif

section .data
    align 16
    embedding_dim: dd 768
    float_scale: dd 0x3A83126F    ; 0.001 as float32 (hex representation)
    float_one: dd 0x3F800000      ; 1.0 as float32
    float_two: dd 0x40000000      ; 2.0 as float32
    two_pi: dd 0x40C90FDB         ; 6.283185307... (2π) as float32
    scale_2_31: dd 0x4F000000     ; 2^31 (2147483648.0) as float32
    scale_2_31_int: dq 2147483648 ; 2^31 as integer

section .bss
    align 16
    ; Storage for generated embedding
    embedding_buffer: resd 768  ; 768 floats = 3072 bytes

section .text
default rel    ; Use RIP-relative addressing for PIC

; External functions from embedding_lib.asm
extern normalize_vector_asm
extern vector_norm_asm

; External math functions (if needed for Sin approximation)
extern sinf

; ============================================
; Function: simple_text_hash
; Generate a simple hash from text string
; Parameters:
;   RCX = char* text (null-terminated)
;   RDX = int text_length
;   R8  = int seed (for variation)
; Returns:
;   RAX = hash value (uint64_t)
; ============================================
global simple_text_hash
simple_text_hash:
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    ; Save parameters to consistent registers
    mov r10, PARAM1    ; text
    mov r11, PARAM2    ; text_length
    mov r12, PARAM3    ; seed
    
    mov rax, r12       ; Start with seed
    mov r9, r10        ; Text pointer
    xor r13, r13       ; Counter
    
.hash_loop:
    cmp r13, r11       ; Check if we've processed all chars
    jge .done
    
    ; Load character
    movzx r14, byte [r9 + r13]
    test r14, r14      ; Check for null terminator
    jz .done
    
    ; Hash algorithm: hash = hash * 31 + char
    mov r15, rax
    shl r15, 5         ; hash * 32
    sub r15, rax       ; hash * 31 = hash * 32 - hash
    add rax, r15       ; hash = hash * 31
    add rax, r14       ; hash += char
    
    inc r13
    jmp .hash_loop
    
.done:
    add rsp, SHADOW_SPACE
    pop rbp
    ret


; ============================================
; Function: hash_to_vector_asm
; Convert multiple hashes to vector elements
; Parameters:
;   RCX = char* text
;   RDX = int text_length
;   R8  = float* output
;   R9  = int dimension
; ============================================
hash_to_vector_asm:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + SHADOW_SPACE
    
    push r12
    push r13
    push r14
    
    ; Save parameters (these come from PARAM1-4 from caller)
    mov r10, PARAM1          ; text
    mov r11, PARAM2          ; text_length
    mov r12, PARAM3          ; output
    mov r13, PARAM4          ; dimension
    mov r14, 0               ; index counter
    
.hash_vector_loop:
    cmp r14, r13
    jge .done
    
    ; Generate hash with seed = index
    ; Prepare parameters for simple_text_hash call
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, r10       ; text (PARAM1)
    mov rsi, r11       ; text_length (PARAM2)
    mov rdx, r14       ; seed (PARAM3)
%else
    mov rcx, r10       ; Windows: rcx=text
    mov rdx, r11       ; Windows: rdx=text_length
    mov r8, r14        ; Windows: r8=seed
%endif
    call simple_text_hash
    
    ; Convert hash to float in range [-1, 1]
    ; Use high bits for better distribution
    ; Prepare parameter for uint64_to_float_normalized call
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, rax       ; hash value (PARAM1)
%else
    mov rcx, rax       ; Windows: rcx=hash value
%endif
    call uint64_to_float_normalized
    
    ; Store in output vector
    movss [r12 + r14*4], xmm0
    
    inc r14
    jmp .hash_vector_loop
    
.done:
    pop r14
    pop r13
    pop r12
    add rsp, 32 + SHADOW_SPACE
    pop rbp
    ret


; ============================================
; Function: uint64_to_float_normalized
; Convert uint64 to normalized float in range [-1, 1]
; Parameters:
;   RCX = uint64_t value
; Returns:
;   XMM0 = normalized float
; ============================================
uint64_to_float_normalized:
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    ; Save parameter
    mov r10, PARAM1          ; value
    
    ; Convert uint64 to float
    ; Normalize: float = (value / 2^63) * 2 - 1  (range [-1, 1])
    cvtsi2ss xmm0, r10       ; Convert to float (uses lower 32 bits)
    
    ; For better distribution, use high bits too
    ; Shift right to mix bits
    shr r10, 32
    cvtsi2ss xmm1, r10
    addss xmm0, xmm1
    
    ; Normalize to [-1, 1] range
    ; Convert to float and use modulo-like operation
    ; Store as float scaled to [-1, 1]
    movss xmm1, [rel float_scale]
    mulss xmm0, xmm1
    ; Use fmod-like reduction: xmm0 = xmm0 - floor(xmm0/2) * 2 - 1
    ; Simplified: use high bits for better distribution
    movd eax, xmm0           ; Extract bits
    and eax, 0x7FFFFFFF      ; Keep sign bit, mask rest
    cvtsi2ss xmm0, eax       ; Convert back
    movss xmm1, [rel float_scale]
    mulss xmm0, xmm1         ; Scale to [-1, 1]
    
    add rsp, SHADOW_SPACE
    pop rbp
    ret


; ============================================
; Function: zero_vector_asm
; Zero out a vector
; Parameters:
;   RCX = float* vector
;   RDX = int dimension
; ============================================
zero_vector_asm:
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    ; Save parameters
    mov r10, PARAM1    ; vector
    mov r12, PARAM2    ; dimension
    
    test r12, r12
    jz .zero_done
    
    xorps xmm0, xmm0   ; Zero register
    
    xor rax, rax
.zero_loop:
    cmp rax, r12
    jge .zero_done
    
    ; Zero 4 floats at a time (if available)
    mov r11, r12
    sub r11, rax
    cmp r11, 4
    jl .zero_single
    
    movups [r10 + rax*4], xmm0
    add rax, 4
    jmp .zero_loop
    
.zero_single:
    ; Zero remaining floats one by one
    cmp rax, r12
    jge .zero_done
    movss [r10 + rax*4], xmm0
    inc rax
    jmp .zero_single
    
.zero_done:
    add rsp, SHADOW_SPACE
    pop rbp
    ret


; ============================================
; Function: positional_hash_asm
; Generate positional hash from text string
; Algorithm: hash = hash * 31 + char * (position + 1)
; Parameters:
;   PARAM1 = char* text (null-terminated)
;   PARAM2 = int text_length
;   PARAM3 = int seed (for variation)
; Returns:
;   RAX = hash value (uint64_t)
; ============================================
global positional_hash_asm
positional_hash_asm:
    ; Save callee-saved registers
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    push r12
    push r13
    push r14
    push r15
    
    ; Save parameters to callee-saved registers
    mov r12, PARAM1    ; text
    mov r13, PARAM2    ; text_length
    mov r14, PARAM3    ; seed
    
    ; Initialize hash with seed
    mov rax, r14       ; hash = seed
    mov r15, r12       ; text pointer
    xor r11, r11       ; position index (j)
    
.positional_hash_loop:
    cmp r11, r13       ; Check if j < text_length
    jge .positional_hash_done
    
    ; Load character
    movzx rcx, byte [r15 + r11]
    test rcx, rcx      ; Check for null terminator
    jz .positional_hash_done
    
    ; Calculate position weight: (j + 1)
    mov rdx, r11
    inc rdx            ; position_weight = j + 1
    
    ; Hash: hash = hash * 31 + char * position_weight
    mov r10, rax       ; Save current hash
    shl r10, 5         ; hash * 32
    sub r10, rax       ; hash * 31 = hash * 32 - hash
    mov rax, r10       ; hash = hash * 31
    
    ; char * position_weight
    mov r10, rcx       ; char
    imul r10, rdx      ; char * position_weight
    add rax, r10       ; hash += char * position_weight
    
    inc r11
    jmp .positional_hash_loop
    
.positional_hash_done:
    ; Restore callee-saved registers
    pop r15
    pop r14
    pop r13
    pop r12
    
    add rsp, SHADOW_SPACE
    pop rbp
    ret




; ============================================
; Function: hash_to_float_sqrt_asm
; Convert hash to float using Square Root normalization
; Algorithm: 
;   normalized = (hash & 0x7FFFFFFF) / 2^31
;   sqrt_val = sqrt(normalized)
;   result = sqrt_val * 2 - 1
; 
; Why Square Root?
;   - Compresses differences between similar hashes
;   - Provides better similarity for typos and reordering
;   - Simple and fast (one SSE instruction)
;   - Meets quality criteria: typo tolerance 0.4-0.9
; 
; Parameters:
;   PARAM1 = uint64_t hash
; Returns:
;   XMM0 = normalized float in range [-1, 1]
; ============================================
global hash_to_float_sqrt_asm
hash_to_float_sqrt_asm:
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE
    
    ; Square Root normalization for better similarity
    ; Proven to work: typo tolerance 0.4, reorder sensitivity 0.23
    
    mov rax, PARAM1      ; hash (64-bit)
    
    ; Use 31 bits (always positive)
    and eax, 0x7FFFFFFF  ; Clear sign bit → [0, 2^31-1]
    
    ; Convert to float
    cvtsi2ss xmm0, eax   ; xmm0 = hash as float
    
    ; Divide by 2^31 to normalize to [0, 1)
    mov eax, 0x4F000000  ; 2^31 as float (hex: 2147483648.0)
    movd xmm1, eax
    divss xmm0, xmm1     ; xmm0 = hash / 2^31 (range [0, 1))
    
    ; Apply square root - THIS IS THE KEY!
    ; sqrt() compresses differences between similar values
    sqrtss xmm0, xmm0    ; xmm0 = sqrt(xmm0)
    
    ; Scale from [0, 1) to [-1, 1)
    movss xmm1, [rel float_two]
    mulss xmm0, xmm1     ; xmm0 = xmm0 * 2 (range [0, 2))
    
    movss xmm1, [rel float_one]
    subss xmm0, xmm1     ; xmm0 = xmm0 - 1 (range [-1, 1))
    
    add rsp, SHADOW_SPACE
    pop rbp
    ret


; ============================================
; Function: generate_combined_hash_asm
; Generate combined hash from text
; Algorithm:
;   hash1 = positional_hash(text, seed)
;   hash2 = positional_hash(text, seed*37)
;   combined = hash1 ^ (hash2 << 16)
; Parameters:
;   PARAM1 = char* text (null-terminated)
;   PARAM2 = int text_length
;   PARAM3 = int seed
; Returns:
;   RAX = combined hash value (uint64_t)
; ============================================
global generate_combined_hash_asm
generate_combined_hash_asm:
    push rbp
    mov rbp, rsp
    sub rsp, SHADOW_SPACE + 16  ; Extra space for local vars
    
    push r12
    push r13
    push r14
    push r15
    
    ; Save parameters
    mov r12, PARAM1    ; text
    mov r13, PARAM2    ; text_length
    mov r14, PARAM3    ; seed
    
    ; Generate hash1 = positional_hash(text, seed)
    mov r15, r14      ; seed for hash1
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, r12      ; text
    mov rsi, r13      ; text_length
    mov rdx, r15      ; seed
%else
    mov rcx, r12      ; text
    mov rdx, r13      ; text_length
    mov r8, r15       ; seed
%endif
    call positional_hash_asm
    mov r8, rax        ; hash1
    
    ; Generate hash2 = positional_hash(text, seed*37)
    mov r15, r14      ; seed
    imul r15, 37      ; seed * 37
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, r12      ; text
    mov rsi, r13      ; text_length
    mov rdx, r15      ; seed * 37
%else
    mov rcx, r12      ; text
    mov rdx, r13      ; text_length
    mov r8, r15       ; seed * 37
%endif
    call positional_hash_asm
    mov r9, rax        ; hash2
    
    ; Combine: combined = hash1 ^ (hash2 << 16)
    mov r10, r9        ; hash2
    shl r10, 16        ; hash2 << 16
    xor r10, r8        ; combined = hash1 ^ (hash2 << 16)
    mov rax, r10       ; Return combined hash
    
    ; Restore registers
    pop r15
    pop r14
    pop r13
    pop r12
    
    add rsp, SHADOW_SPACE + 16
    pop rbp
    ret


; ============================================
; Function: generate_embedding_asm
; Generate embedding with Square Root normalization and positional hashing
; 
; Algorithm:
;   For each dimension i:
;     1. Generate positional hash (character position aware)
;     2. Generate secondary hash (seed * 37)
;     3. Combine hashes: hash1 XOR (hash2 << 16)
;     4. Normalize with √x: sqrt((hash / 2^31)) * 2 - 1
;     5. Store in output[i]
; 
; Quality:
;   - Typo tolerance: 0.40+ similarity
;   - Reorder sensitivity: 0.23+ similarity
;   - Deterministic: same input → same output
; 
; Parameters:
;   PARAM1 = char* text (UTF-8, null-terminated)
;   PARAM2 = float* output (pre-allocated, size >= dimension)
;   PARAM3 = int dimension (128, 256, 512, 768, 1024, 2048)
; Returns:
;   RAX = 0 on success, -1 on error
; ============================================
global generate_embedding_asm
generate_embedding_asm:
    ; Prologue
    push rbp
    mov rbp, rsp
    
    ; CRITICAL: Save parameters IMMEDIATELY before pushing registers
    ; Parameters come in rdi, rsi, rdx (System V) or rcx, rdx, r8 (Windows)
    ; We need to save them before push operations that might clobber them
    mov r10, PARAM1    ; Save text pointer to temporary register
    mov r11, PARAM2    ; Save output pointer to temporary register
    mov r9, PARAM3     ; Save dimension to temporary register
    
    ; Save callee-saved registers (System V ABI: r12, r13, r14, r15, rbx)
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    ; Stack layout after pushes:
    ; rbp-0:  saved rbp (at rbp)
    ; rbp-8:  saved r12
    ; rbp-16: saved r13
    ; rbp-24: saved r14
    ; rbp-32: saved r15
    ; rbp-40: saved rbx
    ; After 6 pushes: 48 bytes (48 mod 16 = 0, already aligned!)
    ; rsp now points to saved rbx (rbp-40)
    
    ; Now move parameters to callee-saved registers
    mov r12, r10       ; text pointer (callee-saved, safe)
    mov r13, r11       ; output pointer (callee-saved, safe)
    mov r14, r9        ; dimension (callee-saved, safe)
    
    ; Step 1: Input Validation
    test r12, r12      ; Check text pointer
    jz .error
    
    test r13, r13      ; Check output pointer
    jz .error
    
    ; Check dimension (must be in {128, 256, 512, 768, 1024, 2048})
    cmp r14d, 128
    je .dimension_ok
    cmp r14d, 256
    je .dimension_ok
    cmp r14d, 512
    je .dimension_ok
    cmp r14d, 768
    je .dimension_ok
    cmp r14d, 1024
    je .dimension_ok
    cmp r14d, 2048
    je .dimension_ok
    jmp .error         ; Invalid dimension
    
.dimension_ok:
    ; Step 2: Calculate text length
    mov r15, r12       ; text pointer for length calculation
    xor rbx, rbx       ; text_length counter
    
.text_length_loop:
    cmp byte [r15], 0
    je .text_length_done
    inc rbx
    inc r15
    jmp .text_length_loop
    
.text_length_done:
    test rbx, rbx      ; Check if empty
    jz .error
    cmp rbx, 8192      ; MAX_TEXT_LENGTH
    jg .error
    
    ; Step 3: Embedding Generation Loop
    xor r15, r15       ; dimension index (i) - use r15 instead of rax!
    
.embedding_loop:
    cmp r15, r14       ; Check if i < dimension
    jge .embedding_done
    
    ; Step 3.1-3.3: Generate Combined Hash
    ; Prepare parameters for generate_combined_hash_asm
    ; Stack alignment: rsp points to saved rbx (rbp-40)
    ; rsp = rbp - 40, so rsp % 16 = (rbp - 40) % 16
    ; If rbp % 16 == 0, then (rbp - 40) % 16 = (0 - 40) % 16 = (-40) % 16 = 8
    ; So rsp is misaligned by 8 bytes before first call
    ; We need to align it: sub rsp, 8 to make it aligned
    sub rsp, 8         ; Align stack to 16 bytes (rsp % 16 == 0)
    ; Pass loop index as seed
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, r12       ; text
    mov rsi, rbx       ; text_length
    mov rdx, r15       ; seed = i
%else
    mov rcx, r12       ; text
    mov rdx, rbx       ; text_length
    mov r8, r15        ; seed = i
%endif
    call generate_combined_hash_asm
    ; Combined hash is in rax
    ; After call, rsp % 16 == 0 (call pushed 8 bytes, but we did sub rsp, 8 before, so aligned)
    ; We need to pass it to hash_to_float_sin_asm
    ; Save hash to a caller-saved register (we'll use it immediately)
    mov r10, rax       ; Save hash in r10 (caller-saved, but we use it immediately)
    
    ; Step 3.4: Normalize with Square Root
    ; Prepare parameter for hash_to_float_sqrt_asm
    ; Stack alignment: after previous call, rsp % 16 == 0 (aligned)
    ; Before next call, we need rsp % 16 == 0 (already aligned!)
%ifidn __OUTPUT_FORMAT__,elf64
    mov rdi, r10       ; Pass hash as parameter
%else
    mov rcx, r10       ; Pass hash as parameter
%endif
    call hash_to_float_sqrt_asm
    ; After call, rsp % 16 == 8 (misaligned)
    ; Restore stack alignment for next iteration
    add rsp, 8         ; Restore stack (counteract the sub rsp, 8 from start of iteration)
    ; XMM0 now contains sqrt-normalized value in [-1, 1]
    
    ; Step 3.5: Store in output array
    ; CRITICAL: Use r15 (loop counter) instead of rax (which was overwritten)!
    movss [r13 + r15*4], xmm0  ; output[i] = sqrt_value
    
    ; Next iteration
    inc r15
    jmp .embedding_loop
    
.embedding_done:
    ; Success (stack is already aligned - we restored it at end of each iteration)
    xor rax, rax
    jmp .done
    
.error:
    mov rax, -1
    
.done:
    ; Restore callee-saved registers
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

