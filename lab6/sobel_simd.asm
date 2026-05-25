global sobel_simd

section .bss
    width:          resq 1
    height:         resq 1
    padded_width:   resq 1
    padded_height:  resq 1
    channels:       resq 1

section .rodata
    align 16
    gx_words: dw -1, 0, 1, -2, 0, 2, -1, 0, 1
    ;gx_last:  dw 1

    align 16
    gy_words: dw 1, 2, 1, 0, 0, 0, -1, -2, -1
    ;gy_last:  dw -1

    align 16
    abs_mask: dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF

section .text

%define input_reg  r12
%define output_reg r13

; void sobel_simd(unsigned char* input,
;                 unsigned char* output,
;                 int width,
;                 int height,
;                 int channels)



sobel_simd:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     input_reg, rdi    ;input
    mov     output_reg, rsi    ;output
    movsxd  rax, edx
    mov     [width], rax    ;width
    movsxd  rax, ecx
    mov     [height], rax   ;height
    movsxd  rax, r8d
    mov     [channels], rax    ;channels

    mov     r10, [width]
    lea     rax, [r10 + 2]
    mov     r10, [height]
    lea     rcx, [r10 + 2]

    mov     [padded_width], rax
    mov     [padded_height], rcx

    mov     rax, [padded_width]
    imul    rax, [padded_height]
    imul    rax, [channels]

    add     rax, 15             ;нужно для округления вверх (перескок к след. числу, кратному 16)
    and     rax, -16            ;-16 = 1111 0000 (обнулим младшие 4 бита для выравнивания стека)
    sub     rsp, rax
    mov     r11, rsp

    xor     rcx, rcx

.pad_y_loop:
    cmp     rcx, [padded_height]
    jge     .pad_done

    xor     rdx, rdx            ; x = 0
.pad_x_loop:
    cmp     rdx, [padded_width]
    jge     .pad_x_done
    lea     rax, [rdx - 1]      ;src_x = x - 1

    test    rax, rax
    jns     .pad_x_max

    xor     rax, rax            ;если x < 0 -> x = 0
    jmp     .src_x_okey
.pad_x_max:
    cmp     rax, [width]
    jl      .src_x_okey

    mov     r10, [width]
    lea     rax, [r10 - 1]
.src_x_okey:
    mov     rdi, rax            ;rdi = src_x

    lea     rax, [rcx - 1]      ;src_y = y - 1

    test    rax, rax
    jns     .pad_y_max

    xor     rax, rax            ;y = 0
    jmp     .src_y_okey
.pad_y_max:
    cmp     rax, [height]
    jl      .src_y_okey
    mov     r10, [height]
    lea     rax, [r10 - 1]
.src_y_okey:
    mov     rsi, rax            ;rsi = src_y

    ;rax = (src_y * width + src_x) * channels
    imul    rax, [width]
    add     rax, rdi
    imul    rax, [channels]
    mov     r15, rax

    ;rax = (y_padded * padded_width + x_padded) * channels
    mov     rax, rcx        ;y_padded
    imul    rax, [padded_width]
    add     rax, rdx        ; + x_padded
    imul    rax, [channels]



    lea     rsi, [input_reg + r15]

    lea     rdi, [r11 + rax]

    push    rcx
    push    rdx

    xor     rcx, rcx
    mov     rcx, [channels]
    rep     movsb            ;копирует 1 байт из rsi в rdi, потом rsi++ rdi++

    pop     rdx
    pop     rcx
    inc     rdx             ;x_padded++
    jmp     .pad_x_loop

.pad_x_done:
    inc     rcx
    jmp     .pad_y_loop

.pad_done:
    ;светрка

    mov     rbx, [channels]
    xor     rcx, rcx        ;y = 0




.y_loop:
    cmp     rcx, [height]
    jge     .finish

    xor     rdx, rdx

.x_loop:
    cmp     rdx, [width]
    jge     .next_row

    xor     r8, r8

.channel_loop:
    cmp     r8, rbx
    jge     .next_x

    ; ------------------------------------------------------------
    ; Загружаем 9 пикселей окна 3x3
    ; p0 p1 p2
    ; p3 p4 p5
    ; p6 p7 p8
    ; ------------------------------------------------------------

    sub     rsp, 32
    pxor    xmm0, xmm0
    movdqu  [rsp], xmm0
    movdqu  [rsp + 16], xmm0
    xor     r9, r9

.load_rows:
    cmp     r9, 3
    jge     .pixels_loaded

    xor     r10, r10

.load_cols:
    cmp     r10, 3
    jge     .next_load_row

    mov     rax, rcx
    add     rax, r9

    imul    rax, [padded_width]

    mov     r14, rdx
    add     r14, r10

    add     rax, r14
    imul    rax, [channels]
    add     rax, r8

    movzx   r15d, byte [r11 + rax]

    mov     r14, r9
    imul    r14, 3
    add     r14, r10

    mov     word [rsp + r14 * 2], r15w

    inc     r10
    jmp     .load_cols

.next_load_row:
    inc     r9
    jmp     .load_rows

.pixels_loaded:

    ; ------------------------------------------------------------
    ; SIMD вычисление Gx
    ; ------------------------------------------------------------

    pxor    xmm0, xmm0
    movdqu  xmm1, [rsp]
    movdqa  xmm2, [rel gx_words]

    pmullw  xmm1, xmm2

    xor     eax, eax

    pextrw  r14d, xmm1, 0
    movsx   r14d, r14w
    add     eax, r14d

    pextrw  r14d, xmm1, 1
    movsx   r14d, r14w
    add     eax, r14d

    pextrw  r14d, xmm1, 2
    movsx   r14d, r14w
    add     eax, r14d

    pextrw  r14d, xmm1, 3
    movsx   r14d, r14w
    add     eax, r14d

    pextrw  r14d, xmm1, 4
    movsx   r14d, r14w
    add     eax, r14d

    pextrw  r14d, xmm1, 5
    movsx   r14d, r14w
    add     eax, r14d

    pextrw  r14d, xmm1, 6
    movsx   r14d, r14w
    add     eax, r14d

    pextrw  r14d, xmm1, 7
    movsx   r14d, r14w
    add     eax, r14d

    movsx   r14d, word [rsp + 16]
    movsx   r15d, word [rel gx_words + 16]
    imul    r14d, r15d
    add     eax, r14d

    mov     r14d, eax


    ; ------------------------------------------------------------
    ; SIMD вычисление Gy
    ; ------------------------------------------------------------

    movdqu  xmm3, [rsp]
    movdqa  xmm4, [rel gy_words]

    pmullw  xmm3, xmm4

    xor     eax, eax

    pextrw  r15d, xmm3, 0
    movsx   r15d, r15w
    add     eax, r15d

    pextrw  r15d, xmm3, 1
    movsx   r15d, r15w
    add     eax, r15d

    pextrw  r15d, xmm3, 2
    movsx   r15d, r15w
    add     eax, r15d

    pextrw  r15d, xmm3, 3
    movsx   r15d, r15w
    add     eax, r15d

    pextrw  r15d, xmm3, 4
    movsx   r15d, r15w
    add     eax, r15d

    pextrw  r15d, xmm3, 5
    movsx   r15d, r15w
    add     eax, r15d

    pextrw  r15d, xmm3, 6
    movsx   r15d, r15w
    add     eax, r15d

    pextrw  r15d, xmm3, 7
    movsx   r15d, r15w
    add     eax, r15d

    movsx   r15d, word [rsp + 16]
    movsx   r9d, word [rel gy_words + 16]
    imul    r15d, r9d
    add     eax, r15d

    mov     r15d, eax

    add     rsp, 32

    ; ------------------------------------------------------------
    ; magnitude = abs(sum_x) + abs(sum_y)
    ; ------------------------------------------------------------

    mov     eax, r14d
    mov     r9d, eax
    sar     r9d, 31
    xor     eax, r9d
    sub     eax, r9d

    mov     esi, eax

    mov     eax, r15d
    mov     r9d, eax
    sar     r9d, 31
    xor     eax, r9d
    sub     eax, r9d

    add     eax, esi


    cmp     eax, 255
    jle     .store_pixel

    mov     eax, 255

.store_pixel:

    mov     rsi, rcx
    imul    rsi, [width]
    add     rsi, rdx
    imul    rsi, [channels]
    add     rsi, r8

    mov     byte [output_reg + rsi], al

    inc     r8
    jmp     .channel_loop

.next_x:
    inc     rdx
    jmp     .x_loop

.next_row:
    inc     rcx
    jmp     .y_loop

.finish:
    ;mov     rsp, rbp
    lea     rsp, [rbp - 40]

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp

    ret