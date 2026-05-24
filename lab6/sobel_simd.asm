global sobel_simd

section .bss
    width:  resq 1
    height: resq 1
    padded_width: resq 1
    padded_height: resq 1
    channels: resq 1
    sum_x: resq 1
    sum_y: resq 1

section .rodata
    Gx_row0:  db  -1, 0, 1, -1, 0, 1, -1, 0, 1, -1, 0, 1, -1, 0, 1, -1
    Gx_row1:  db  -2, 0, 2, -2, 0, 2, -2, 0, 2, -2, 0, 2, -2, 0, 2, -2
    Gx_row2:  db  -1, 0, 1, -1, 0, 1, -1, 0, 1, -1, 0, 1, -1, 0, 1, -1

    Gy_row0:  db   1, 2, 1,  1, 2, 1,  1, 2, 1,  1, 2, 1,  1, 2, 1,  1
    Gy_row1:  db   0, 0, 0,  0, 0, 0,  0, 0, 0,  0, 0, 0,  0, 0, 0,  0
    Gy_row2:  db  -1,-2,-1, -1,-2,-1, -1,-2,-1, -1,-2,-1, -1,-2,-1, -1

section .text

%define input_reg  r12
%define output_reg r13

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
    mov     ecx, dword [channels]
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




.conv_y_loop:
    cmp     rcx, [height]
    jge     .conv_done
    xor     rdx, rdx           ; x = 0

.conv_x_loop:
    cmp     rdx, [width]
    jge     .conv_x_done
    xor     r8, r8             ; c = 0

.channel_loop:
    cmp     r8, rbx
    jge     .channel_done

    ; --- Адреса трёх строк padded_img для канала c ---
    mov     rax, rcx
    mov     r10, [padded_width]
    imul    rax, r10
    mov     r10, [channels]
    imul    rax, r10
    add     rax, r8
    lea     r14, [r11 + rax]   ; r14 = &padded[y][0][c]

    mov     r10, [padded_width]
    imul    r10, [channels]    ; шаг строки в байтах
    lea     r15, [r14 + r10]   ; r15 = &padded[y+1][0][c]
    lea     r9, [r15 + r10]    ; r9  = &padded[y+2][0][c]

    ; --- Цикл по x с шагом 16 ---
    mov     rsi, rdx           ; rsi = текущий x
    mov     rdi, [width]
    sub     rdi, rdx           ; rdi = осталось пикселей

.simd_x_loop:
    cmp     rdi, 16
    jl      .simd_rest

    ; ===== 16 ПИКСЕЛЕЙ ЗА РАЗ =====
    mov     rax, rsi
    mov     r10, [channels]
    imul    rax, r10           ; смещение в байтах до x

    movdqu  xmm0, [r14 + rax]  ; строка y
    movdqu  xmm1, [r15 + rax]  ; строка y+1
    movdqu  xmm2, [r9 + rax]   ; строка y+2

    ; Распаковка байт → слова
    pxor    xmm7, xmm7
    movdqa  xmm3, xmm0
    punpcklbw xmm0, xmm7
    punpckhbw xmm3, xmm7
    movdqa  xmm4, xmm1
    punpcklbw xmm1, xmm7
    punpckhbw xmm4, xmm7
    movdqa  xmm5, xmm2
    punpcklbw xmm2, xmm7
    punpckhbw xmm5, xmm7

    ; --- Gx: младшие 8 ---
    movdqa  xmm6, xmm0
    pmullw  xmm6, [Gx_row0]
    movdqa  xmm8, xmm1
    pmullw  xmm8, [Gx_row1]
    paddw   xmm6, xmm8
    movdqa  xmm8, xmm2
    pmullw  xmm8, [Gx_row2]
    paddw   xmm6, xmm8         ; xmm6 = sum_x (младшие 8)

    ; --- Gx: старшие 8 ---
    movdqa  xmm10, xmm3
    pmullw  xmm10, [Gx_row0]
    movdqa  xmm8, xmm4
    pmullw  xmm8, [Gx_row1]
    paddw   xmm10, xmm8
    movdqa  xmm8, xmm5
    pmullw  xmm8, [Gx_row2]
    paddw   xmm10, xmm8        ; xmm10 = sum_x (старшие 8)

    ; --- Gy: младшие 8 ---
    movdqa  xmm11, xmm0
    pmullw  xmm11, [Gy_row0]
    movdqa  xmm8, xmm1
    pmullw  xmm8, [Gy_row1]
    paddw   xmm11, xmm8
    movdqa  xmm8, xmm2
    pmullw  xmm8, [Gy_row2]
    paddw   xmm11, xmm8        ; xmm11 = sum_y (младшие 8)

    ; --- Gy: старшие 8 ---
    movdqa  xmm12, xmm3
    pmullw  xmm12, [Gy_row0]
    movdqa  xmm8, xmm4
    pmullw  xmm8, [Gy_row1]
    paddw   xmm12, xmm8
    movdqa  xmm8, xmm5
    pmullw  xmm8, [Gy_row2]
    paddw   xmm12, xmm8        ; xmm12 = sum_y (старшие 8)

    ; --- |sum_x| + |sum_y| ---
    pabsw   xmm6, xmm6
    pabsw   xmm10, xmm10
    pabsw   xmm11, xmm11
    pabsw   xmm12, xmm12
    paddw   xmm6, xmm11
    paddw   xmm10, xmm12

    ; --- Упаковка слов в байты с насыщением (clamp 0..255) ---
    packuswb xmm6, xmm10

    ; --- Сохранение 16 байт ---
    mov     rax, rcx
    mov     r10, [width]
    imul    rax, r10
    add     rax, rsi
    mov     r10, [channels]
    imul    rax, r10
    add     rax, r8
    movdqu  [output_reg + rax], xmm6

    add     rsi, 16
    sub     rdi, 16
    jmp     .simd_x_loop

.simd_rest:
    cmp     rdi, 0
    jle     .simd_channel_done

    mov     qword [sum_x], 0
    mov     qword [sum_y], 0

    mov     rax, rsi
    mov     r10, [channels]
    imul    rax, r10


    movzx   r10d, byte [r14 + rax]
    movsx   r11d, byte [Gx_row0]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row0]
    imul    r11d, r10d
    add     [sum_y], r11

    ; ky=0, kx=1
    movzx   r10d, byte [r14 + rax + 3]
    movsx   r11d, byte [Gx_row0 + 1]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row0 + 1]
    imul    r11d, r10d
    add     [sum_y], r11

    ; ky=0, kx=2
    movzx   r10d, byte [r14 + rax + 6]
    movsx   r11d, byte [Gx_row0 + 2]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row0 + 2]
    imul    r11d, r10d
    add     [sum_y], r11

    ; ky=1, kx=0
    movzx   r10d, byte [r15 + rax]
    movsx   r11d, byte [Gx_row1]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row1]
    imul    r11d, r10d
    add     [sum_y], r11

    ; ky=1, kx=1
    movzx   r10d, byte [r15 + rax + 3]
    movsx   r11d, byte [Gx_row1 + 1]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row1 + 1]
    imul    r11d, r10d
    add     [sum_y], r11

    ; ky=1, kx=2
    movzx   r10d, byte [r15 + rax + 6]
    movsx   r11d, byte [Gx_row1 + 2]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row1 + 2]
    imul    r11d, r10d
    add     [sum_y], r11

    ; ky=2, kx=0
    movzx   r10d, byte [r9 + rax]
    movsx   r11d, byte [Gx_row2]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row2]
    imul    r11d, r10d
    add     [sum_y], r11

    ; ky=2, kx=1
    movzx   r10d, byte [r9 + rax + 3]
    movsx   r11d, byte [Gx_row2 + 1]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row2 + 1]
    imul    r11d, r10d
    add     [sum_y], r11

    ; ky=2, kx=2
    movzx   r10d, byte [r9 + rax + 6]
    movsx   r11d, byte [Gx_row2 + 2]
    imul    r11d, r10d
    add     [sum_x], r11
    movsx   r11d, byte [Gy_row2 + 2]
    imul    r11d, r10d
    add     [sum_y], r11

    ; magnitude = |sum_x| + |sum_y|
    mov     r10, [sum_x]
    mov     rax, r10
    sar     rax, 63
    xor     r10, rax
    sub     r10, rax           ; r10 = |sum_x|

    mov     rax, [sum_y]
    mov     rdi, rax           ; ← rdi (он уже не нужен после dec rdi)
    sar     rdi, 63
    xor     rax, rdi
    sub     rax, rdi           ; rax = |sum_y|

    add     r10d, eax          ; magnitude

    ; clamp
    test    r10d, r10d
    jns     .rest_check_max
    xor     r10d, r10d
    jmp     .rest_store
.rest_check_max:
    cmp     r10d, 255
    jle     .rest_store
    mov     r10d, 255

.rest_store:
    mov     rax, rcx
    mov     rdi, [width]       ; ← rdi
    imul    rax, rdi
    add     rax, rsi
    mov     rdi, [channels]    ; ← rdi
    imul    rax, rdi
    add     rax, r8
    mov     byte [output_reg + rax], r10b

    inc     rsi
    dec     rdi
    jmp     .simd_rest

.simd_channel_done:
    inc     r8
    jmp     .channel_loop

.channel_done:
    inc     rdx
    jmp     .conv_x_loop

.conv_x_done:
    inc     rcx
    jmp     .conv_y_loop

.conv_done:
    lea     rsp, [rbp - 40]
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret