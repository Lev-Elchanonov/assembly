section .data
	fmt_input_x db "Enter x (|x|<=1): ", 0
	fmt_input_eps db "Enter precision: ", 0
	double db "%lf", 0
	mode_write db "w", 0
	fmt_print_left db "Left side (arccos): %.15f", 10, 0
	fmt_print_right db "Right side (arccos): %.15f", 10, 0
	term_output db "n = %d, term = %.15f", 10, 0
	err_msg db "Error: cant open file", 10, 0
	err_env db "Error: envp != 2", 10, 0
	invalid_x_msg db "Error: x must be |x|<=1", 10, 0
	invalid_eps_msg db "Error: eps must be > 0", 10, 0
	pi_value dq 1.5707963267948966

section .rodata
	four dq	4.0
	one  dq 1.0
section .bss
	x resq 1
	eps resq 1
	term resq 1
	factorial_pars resq 1
	file_handle resq 1
	n resq 1
	filename_ptr resq 1
	left_result resq 1
	right_result resq 1

section .note.GNU-stack progbits

section .text
	extern printf, scanf, fopen, fprintf, fclose, exit, pow, fabs, asin
	global main

main:
	push	rbp
	mov	rbp, rsp

	cmp	edi, 2
	jne	.error_argv
	mov	rax, [rsi + 8]
	mov	[filename_ptr], rax

	mov	rdi, fmt_input_x
	xor	rax, rax
	call 	printf

	mov	rdi, double
	mov	rsi, x
	xor	rax, rax
	call	scanf
	
	call	check_x
	
	mov	rdi, fmt_input_eps
	xor	rax, rax
	call 	printf

	mov	rdi, double
	mov	rsi, eps
	xor	rax, rax
	call	scanf
	
	call	check_eps

	; открытие файла
	mov	rdi, [filename_ptr]
	mov	rsi, mode_write
	call	fopen
	test	rax, rax
	jz	.file_error
	mov	[file_handle], rax	;rax - указатель на файл

	
	; arccos 1ым способом
	movsd	xmm0, [x]
	call	arccos_left_compute
	movsd	[left_result], xmm0

	; arccos 2ым способом
	call	compute_series

	mov	rdi, fmt_print_left	
	mov	rax, 1
	movsd	xmm0, [left_result]
	call	printf
	
	mov	rdi, fmt_print_right
	mov	rax, 1
	movsd	xmm0, [right_result]
	call	printf


	mov	rdi, [file_handle]
	call	fclose
	
	xor	rax, rax
	pop	rbp
	ret


.error_argv:
	mov	rdi, err_env
	xor	rax, rax
	call	printf
	mov	rdi, 1
	call	exit

.file_error:
	mov	rdi, err_msg
	xor	rax, rax
	call	printf
	mov 	rdi, 1
	call	exit


check_x:
	movsd	xmm0, [x]
	call	fabs
	movsd	xmm1, [one]
	comisd	xmm0, xmm1
	ja	.error_x ;above
	ret
.error_x:
	mov     rdi, invalid_x_msg
	xor     rax, rax
	call    printf
	mov     rdi, 1
	call    exit



check_eps:
	movsd	xmm0, [eps]
	pxor	xmm2, xmm2
	comisd	xmm0, xmm2
	jbe	.error_eps	;below or equal
	ret
.error_eps:
	mov	rdi, invalid_eps_msg
	xor	rax, rax
	call	printf
	mov	rdi, 1
	call	exit	
	

arccos_left_compute:
	sub	rsp, 8
	movsd	[rsp], xmm0
	;fld qword	[rsp]
	
	call	asin
	
	movsd	xmm1, [pi_value]
	subsd	xmm1, xmm0
	movsd	xmm0, xmm1
	add	rsp, 8
	ret

compute_series:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48
	
	mov qword [n], 0
	pxor	xmm1, xmm1
	movsd	[right_result], xmm1
	
	movsd	xmm0, [x]
	movsd	[rsp], xmm0

	movsd	xmm1, [eps]
	movsd	[rsp + 40], xmm1

.series_loop:
	mov	rax, [n]
	call	factorial_2n
	movsd	[rsp + 8], xmm0
	
	mov	rax, [n]
	call	pow_4n
	movsd	[rsp + 16], xmm0
	
	mov	rax, [n]
	call	factorial_n
	mulsd	xmm0, xmm0
	movsd 	[rsp + 24], xmm0

	mov	rax, [n]
	add	rax, rax
	inc	rax

	cvtsi2sd	xmm0, rax
	mulsd	xmm0, [rsp + 16]	;4^n * (2n + 1)
	mulsd	xmm0, [rsp + 24]	;4^n * (2n + 1) * (n!)^2

	movsd	xmm1, [rsp + 8]		; xmm1 = (2n)!
	divsd	xmm1, xmm0		; результат в первый операнд

	
	mov	rax, [n]
	add	rax, rax
	inc	rax			; rax = (2n + 1)
	
	movsd	[rsp + 32], xmm1	
	call	pow_x			; xmm0 = x^(2n + 1)
	movsd	xmm1, [rsp + 32]
	mulsd	xmm1, xmm0
	
	movsd	[term], xmm1
	movsd	xmm0, [term]

	call	fabs
	movsd	xmm1, [rsp + 40]	
	comisd	xmm0, xmm1
	jb	.series_done		;below (xmm0 < xmm1)
	
	
	;запись в файл
	call	fprintf_call

	;запись члена ряда
	movsd	xmm0, [right_result]
	addsd	xmm0, [term]
	movsd	[right_result], xmm0
	
	inc	qword [n]
	jmp	.series_loop

.series_done:
	movsd	xmm0, [right_result]
	addsd	xmm0, [term]
	movsd	[right_result], xmm0
	call	fprintf_call

	movsd	xmm0, [pi_value]
	subsd	xmm0, [right_result]
	movsd	[right_result], xmm0
	leave
	ret


fprintf_call:
	push	rbp
	mov	rbp, rsp

	mov     rdi, [file_handle]
        mov     rsi, term_output
        mov     rdx, [n]
        movsd   xmm0, [term]
        mov     rax, 1
        call    fprintf
	
	pop	rbp		
	ret
	


factorial_2n:
	push	rbp
	mov	rbp, rsp
	mov	rcx, rax	; rcx = n
	add	rcx, rcx	; 2n
	mov	r10, 1
	cvtsi2sd xmm0, r10
	mov	rax, 1		

.loop:
	cmp	rax, rcx
	jg	.done
	cvtsi2sd xmm1, rax
	mulsd	xmm0, xmm1
	
	inc	rax	
	jmp	.loop

.done:
	pop	rbp
	ret

factorial_n:
	push	rbp
	mov	rbp, rsp
	mov	rcx, rax
	mov	r10, 1
	cvtsi2sd xmm0, r10
	mov	rax, 1
.loop:
    cmp     rax, rcx
    jg      .done
    cvtsi2sd xmm1, rax
    mulsd   xmm0, xmm1
    inc     rax
    jmp     .loop
.done:
    pop     rbp
    ret


pow_4n:
	push	rbp
	mov	rbp, rsp
	mov	rcx, rax	; rcx = n
	mov	r10, 1
	cvtsi2sd xmm0, r10
	test	rcx, rcx
	jz	.p4n_done
	movsd	xmm1, [four]

.p4n_loop:
	test	rcx, rcx
	jz	.p4n_done
	mulsd	xmm0, xmm1
	dec	rcx
	jmp	.p4n_loop
	

.p4n_done:
	pop	rbp
	ret




pow_x:
	push	rbp
	mov	rbp, rsp
	mov	r10, 1
	cvtsi2sd xmm0, r10
	test	rax, rax
	jz	.pow_done
	movsd	xmm1, [x]

.pow_loop:
	test 	rax, rax
	jz	.pow_done
	mulsd	xmm0, xmm1		
	dec	rax
	jmp	.pow_loop


.pow_done:
	pop	rbp
	ret




















