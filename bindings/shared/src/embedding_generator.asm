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
    float_scale: dd 0.001    ; Small scale factor for normalization
    float_one: dd 1.0        ; Constant 1.0

section .bss
    align 16
    ; Storage for generated embedding
    embedding_buffer: resd 768  ; 768 floats = 3072 bytes

section .text
default rel    ; Use RIP-relative addressing for PIC

; External functions from embedding_lib.asm
extern normalize_vector_asm
extern vector_norm_asm

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
; Function: generate_simple_embedding
; Generate a simple 768-dim embedding from text
; This is a placeholder - real embeddings require trained models
; Parameters (Windows x64):
;   RCX = char* text (UTF-8, null-terminated)
;   RDX = float* output (768 floats, pre-allocated)
; Returns:
;   RAX = 0 on success, -1 on error
; ============================================
global generate_simple_embedding
generate_simple_embedding:
    ; Save callee-saved registers
    push r12
    push r13
    push r14
    push r15
    
    ; Save parameters to callee-saved registers
    mov r12, PARAM1    ; text pointer
    mov r13, PARAM2    ; output pointer
    
    ; Calculate text length (null-terminated string)
    mov r14, r12       ; text pointer for length calculation
    xor r15, r15       ; text_length counter
.text_length_loop:
    cmp byte [r14], 0
    je .text_length_done
    inc r15
    inc r14
    jmp .text_length_loop
.text_length_done:
    
    ; Initialize output index
    xor rax, rax       ; output index (0..767)
    
.embedding_loop:
    cmp rax, 768
    jge .embedding_done
    
    ; ========================================
    ; Inline hash calculation (seed = index)
    ; Hash algorithm: hash = seed * 31 + char1 * 31 + char2 * 31 + ...
    ; ========================================
    mov r10, rax       ; Start hash with seed (index)
    mov r11, r12        ; Text pointer
    xor r14, r14       ; Character index
    
.hash_char_loop:
    cmp r14, r15       ; Check if we've processed all chars
    jge .hash_done
    
    ; Load character
    movzx rcx, byte [r11 + r14]
    test rcx, rcx      ; Check for null terminator
    jz .hash_done
    
    ; Hash: hash = hash * 31 + char
    mov rdx, r10       ; Save current hash
    shl rdx, 5         ; hash * 32
    sub rdx, r10       ; hash * 31 = hash * 32 - hash
    add r10, rdx       ; hash = hash * 31
    add r10, rcx       ; hash += char
    
    inc r14
    jmp .hash_char_loop
    
.hash_done:
    ; r10 now contains the hash value (uint64)
    
    ; ========================================
    ; Inline hash to float conversion (range [-1, 1])
    ; ========================================
    ; Convert uint64 to float and normalize to [-1, 1]
    ; Strategy: use modulo operation with large prime, then scale
    
    ; Use low 32 bits of hash (more uniform distribution)
    mov rdx, r10
    and rdx, 0xFFFFFFFF
    
    ; Convert to float
    cvtsi2ss xmm0, rdx
    
    ; Normalize: use modulo-like operation with 2^31
    ; float_value = (hash % (2^31)) / (2^31) * 2 - 1  -> range [-1, 1]
    ; Simplified: use high bits to create variation
    
    ; Extract bits for better distribution
    mov rdx, r10
    shr rdx, 16           ; Use middle 16 bits
    and rdx, 0xFFFF       ; Keep only low 16 bits
    cvtsi2ss xmm1, rdx
    mulss xmm1, [rel float_scale]  ; Scale down (0.001)
    addss xmm0, xmm1      ; Add variation
    
    ; Normalize to [-1, 1] range
    ; Use: value = sin(hash) approximation via bit manipulation
    ; Simplified: map hash bits to [-1, 1]
    movd edx, xmm0        ; Get float bits
    and edx, 0x7FFFFFFF  ; Keep sign, mask rest to positive
    cvtsi2ss xmm0, edx    ; Convert to float
    
    ; Scale to [0, 1] then to [-1, 1]
    ; Divide by max int32 value
    mov rdx, 2147483647  ; Max signed int32
    cvtsi2ss xmm1, rdx
    divss xmm0, xmm1      ; Normalize to [0, 1]
    
    ; Map [0, 1] to [-1, 1]: value = value * 2 - 1
    movss xmm1, [rel float_one]   ; Load 1.0
    mulss xmm0, xmm1
    mulss xmm0, xmm1      ; Multiply by 2 (xmm1 = 1.0)
    subss xmm0, xmm1      ; Subtract 1 -> range [-1, 1]
    
    ; Store float in output array
    movss [r13 + rax*4], xmm0
    
    ; Next iteration
    inc rax
    jmp .embedding_loop
    
.embedding_done:
    ; Success
    xor rax, rax
    
    ; Restore callee-saved registers
    pop r15
    pop r14
    pop r13
    pop r12
    ret
    
.error:
    mov rax, -1              ; Return error
    jmp .done
    
.done:
    ; Restore callee-saved registers
    pop r12
    add rsp, 16
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
    jz .done
    
    xorps xmm0, xmm0   ; Zero register
    
    xor rax, rax
.zero_loop:
    cmp rax, r12
    jge .done
    
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
    jge .done
    movss [r10 + rax*4], xmm0
    inc rax
    jmp .zero_single
    
.done:
    add rsp, SHADOW_SPACE
    pop rbp
    ret

