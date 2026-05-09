global edge_detection_asm

section .bss
    width:  resq 1
    height: resq 1
    padded_width: resq 1
    padded_height: resq 1
    channels: resq 1
    accumulator: resq 1

section .rodata
    kernel:  db  -1, -1, -1
             db  -1,  8, -1
             db  -1, -1, -1
section .text

;extern void edge_detection_asm(unsigned char* input, unsigned char* output, int width, int height, int channels);
%define input_reg r12
%define output_reg r13


edge_detection_asm:
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

    add     rax, 15
    and     rax, -16
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
    rep     movsb            ;копирует 1 байт из rsi в rdi

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

    xor     rdx, rdx        ;x = 0

.conv_x_loop:
    cmp     rdx, [width]
    jge     .conv_x_done

    xor     r8, r8          ;c = 0

.channel_loop:
    cmp     r8, rbx
    jge     .channel_done

    xor     rax, rax
    mov     qword [accumulator], 0
    xor     r9, r9          ;ky = 0

.ky_loop:
    cmp     r9, 3
    jge     .ky_done

    xor     r10, r10        ;kx = 0

.kx_loop:
    cmp     r10, 3
    jge     .kx_done

    lea     rsi, [rcx + r9]     ;py = y + ky
    lea     rdi, [rdx + r10]    ;px = x + kx

    ;pixel = (py * padded_width + px) * channels + c
    mov     rax, rsi            ;rax = py
    imul    rax, [padded_width] ;rax = py * padded_width
    add     rax, rdi            ;rax = py + padded_width + px
    imul    rax, [channels]
    add     rax, r8

    movzx   rax, byte [r11 + rax];загрузка пикселя

    ;k_index = ky * 3 + kx
    mov     r15, r9
    imul    r15, r15, 3
    add     r15, r10

    movsx   r15, byte [kernel + r15]

    imul    rax, r15
    add     [accumulator], rax

    inc     r10
    jmp     .kx_loop

.kx_done:
    inc     r9
    jmp     .ky_loop

.ky_done:
    mov     rax, [accumulator]
    test    rax, rax
    jns     .check_max

    xor     rax, rax
    jmp     .store_pixel
.check_max:
    cmp     rax, 255
    jle     .store_pixel
    mov     rax, 255

.store_pixel:
    ;index в output (y * width + x) * channels + c
    mov     rsi, rcx
    imul    rsi, [width]
    add     rsi, rdx
    imul    rsi, [channels]
    add     rsi, r8

    mov    byte [output_reg + rsi], al

    inc    r8
    jmp    .channel_loop

.channel_done:
    inc     rdx
    jmp     .conv_x_loop

.conv_x_done:
    inc     rcx
    jmp     .conv_y_loop

.conv_done:
    mov     rsp, rbp
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

