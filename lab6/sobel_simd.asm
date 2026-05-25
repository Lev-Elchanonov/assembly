global sobel_simd

section .bss
    width:  resq 1
    height: resq 1
    padded_width: resq 1
    padded_height: resq 1
    channels: resq 1


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
    mov     rcx, 1



.y_loop:
    mov     rax, [height]
    dec     rax                  ; height - 1
    cmp     rcx, rax
    jge     .finish

    mov     rdx, 1

.x_loop:
    mov     rax, [width]
    dec     rax
    sub     rax, 8
    cmp     rdx, rax
    jge      .next_row


    mov     r8, rcx
    dec     r8
    imul    r8, [padded_width]      ; row0 = (y-1) * padded_width

    mov     r9, rcx
    imul    r9, [padded_width]      ; row1 = y * padded_width

    mov     r10, rcx
    inc     r10
    imul    r10, [padded_width]     ; row2 = (y+1) * padded_width

    add     r8, rdx
    add     r9, rdx
    add     r10, rdx

    pxor    xmm15, xmm15            ; xmm15 = 0 (для распаковки)

    ;Gx = (-1)·p(-1,-1) + (0)·p(0,-1) + (+1)·p(1,-1) +
    ;     (-2)·p(-1,0)  + (0)·p(0,0)  + (+2)·p(1,0)  +
    ;     (-1)·p(-1,1)  + (0)·p(0,1)  + (+1)·p(1,1)

    ;Gy = (+1)·p(-1,-1) + (+2)·p(0,-1) + (+1)·p(1,-1) +
    ;     (0) ·p(-1,0)  + (0) ·p(0,0)  + (0) ·p(1,0)  +
    ;     (-1)·p(-1,1)  + (-2)·p(0,1)  + (-1)·p(1,1)

    ;magnitude = |Gx| + |Gy|

    ; ОБРАБОТКА GX
    movdqu  xmm0, [r11 + r8 - 1]    ; top-left      $
    movdqu  xmm2, [r11 + r8 + 1]    ; top-right
    movdqu  xmm3, [r11 + r9 - 1]    ; mid-left
    movdqu  xmm5, [r11 + r9 + 1]    ; mid-right
    movdqu  xmm6, [r11 + r10 - 1]   ; bot-left
    movdqu  xmm8, [r11 + r10 + 1]   ; bot-right

    ; --- Распаковка: байты → слова ---
    ; top-right - top-left
    movdqa  xmm9, xmm2              ;для копирования регистров xmm
    punpcklbw xmm2, xmm15           ; младшие 8: слова  (берет младшие 8 байти и чередует их)
    punpckhbw xmm9, xmm15           ; старшие 8: слова  (берет старшие 8 байт и чередует их)
    movdqa  xmm10, xmm0             ; top left
    punpcklbw xmm0, xmm15           ; младшие 8 слов
    punpckhbw xmm10, xmm15          ; старшие 8 слов
    psubw   xmm2, xmm0              ; top_right - top_left (младшие)    (packed substract words - вычитание 88 знаковых слов) (из каждого слова в xmm2 вычитается каждое слово в xmm0)
    psubw   xmm9, xmm10             ; top_right - top_left (старшие)

    ; 2 * (mid_right - mid_left)
    movdqa  xmm11, xmm5             ; mid right
    punpcklbw xmm5, xmm15           ; младшие 8 слов
    punpckhbw xmm11, xmm15          ; старшие 8 слов
    movdqa  xmm12, xmm3             ; mid left
    punpcklbw xmm3, xmm15           ; младшие 8 слов
    punpckhbw xmm12, xmm15          ; старшие 8 слов
    psubw   xmm5, xmm3              ; mid_right - mid_left (младшие)
    psubw   xmm11, xmm12            ; mid_right - mid_left (старшие)
    paddw   xmm5, xmm5              ; *2 (младшие)
    paddw   xmm11, xmm11            ; *2 (старшие)

    ; bot_right - bot_left
    movdqa  xmm13, xmm8             ; bot right
    punpcklbw xmm8, xmm15           ; младшие 8 слов
    punpckhbw xmm13, xmm15          ; старшие 8 слов
    movdqa  xmm14, xmm6             ; bot left
    punpcklbw xmm6, xmm15           ; младшие 8 слов
    punpckhbw xmm14, xmm15          ; старшие 8 слов
    psubw   xmm8, xmm6              ; bot_right - bot_left (младшие)
    psubw   xmm13, xmm14            ; bot_right - bot_left (старшие)

    ; Суммируем Gx
    paddw   xmm2, xmm5
    paddw   xmm2, xmm8              ; xmm2 = Gx (младшие 8)
    paddw   xmm9, xmm11
    paddw   xmm9, xmm13             ; xmm9 = Gx (старшие 8)

    ; ===== Gy =====

    ; top_row = top_left + 2*top_mid + top_right
    movdqu  xmm0, [r11 + r8 - 1]    ; top_left
    movdqu  xmm1, [r11 + r8]        ; top_mid
    movdqu  xmm4, [r11 + r8 + 1]    ; top_right
    movdqa  xmm5, xmm0
    punpcklbw xmm0, xmm15           ; top_left (младшие 8)
    punpckhbw xmm5, xmm15           ; top_left (старшие 8)
    movdqa  xmm6, xmm1
    punpcklbw xmm1, xmm15           ; top_mid (младшие 8)
    punpckhbw xmm6, xmm15           ; top_mid (старшие 8)
    paddw   xmm1, xmm1              ; 2*top_mid (младшие)
    paddw   xmm6, xmm6              ; 2*top_mid (старише)
    paddw   xmm0, xmm1              ; top_left + top_mid (в младших)
    paddw   xmm5, xmm6              ; top_left + top_mid (в старших)
    movdqa  xmm7, xmm4
    punpcklbw xmm4, xmm15           ; top_right (младшие 8)
    punpckhbw xmm7, xmm15           ; top_right (старшие 8)
    paddw   xmm0, xmm4              ; top_sum (младшие)
    paddw   xmm5, xmm7              ; top_sum (старшие)

    ; bot_row = bot_left + 2*bot_mid + bot_right
    movdqu  xmm10, [r11 + r10 - 1]  ; bot_left
    movdqu  xmm11, [r11 + r10]      ; bot_mid
    movdqu  xmm12, [r11 + r10 + 1]  ; bot_right
    movdqa  xmm13, xmm10
    punpcklbw xmm10, xmm15          ; bot_left (младшие 8)
    punpckhbw xmm13, xmm15          ; bot_left (старшие 8)
    movdqa  xmm14, xmm11
    punpcklbw xmm11, xmm15          ; bot_mid (младшие 8)
    punpckhbw xmm14, xmm15          ; bot_mid (старшие 8)
    paddw   xmm11, xmm11            ; 2*bot_mid (младшие)
    paddw   xmm14, xmm14            ; 2*bot_mid (старшие)
    paddw   xmm10, xmm11            ; bot_left + 2*bot_mid (младшие)
    paddw   xmm13, xmm14            ; bot_left + 2*bot_mid (старшие)
    movdqa  xmm1, xmm12
    punpcklbw xmm12, xmm15          ; bot_right (младшие)
    punpckhbw xmm1, xmm15           ; bot_right (старшие)
    paddw   xmm10, xmm12            ; bot_sum (младшие)
    paddw   xmm13, xmm1             ; bot_sum (старшие)

    ; Gy = top_sum - bot_sum
    psubw   xmm0, xmm10             ; Gy (младшие)
    psubw   xmm5, xmm13             ; Gy (старшие)

    ; Модуль Gx
    pabsw   xmm2, xmm2
    pabsw   xmm9, xmm9

    ; Модуль Gy
    pabsw   xmm0, xmm0
    pabsw   xmm5, xmm5

    ; Модуль Gx + Модуль Gy
    paddw   xmm2, xmm0
    paddw   xmm9, xmm5

    packuswb xmm2, xmm9             ; Конвертация слов в байты

    mov     r14, rcx
    imul    r14, [width]
    add     r14, rdx                ; r14 = y * width + x
    movdqu  [output_reg + r14], xmm2

    add     rdx, 16                  ; 16 пикселей за раз (16 байт = 8 слов)
    jmp     .x_loop

.next_row:
    inc     rcx
    jmp     .y_loop

.finish:
    lea     rsp, [rbp - 40]
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret