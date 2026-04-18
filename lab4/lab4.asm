section .data
	fmt_input_x db "Enter x (|x|<=1): ", 0
	fmt_input_eps db "Enter precision: ", 0
	double db "%lf", 0
	mode_write db "w", 0
	fmt_print_left db "Left side (arccos): %.15f", 10, 0
	fmt_print_right db "Right side (arccos): %.15f", 10, 0
	fmt_file db "n = %d, term = %.15f", 10, 0
	err_msg db "Error: cant open file", 10, 0
	err_env db "Error: envp != 2", 10, 0
	invalid_x_msg db "Error: x must be |x|<=1", 10, 0
	pi_value dq 1.5707963267948966

section .rodata
	four dq	4.0

section .bss
	x resq 1
	eps resq 1
	term resq 1
	sum resq 1
	factorial_pars resq 1
	file_handle resq 1
	n resq 1
	filename_ptr resq 1

section .note.GNU-stack progbits

section .text
	extern printf, scanf, fopen, fprintf, fclose, exit, pow, fabs
	global main

main:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 16

	cmp	edi, 2
	jne	.error_argv
	mov	rax, [rsi + 8]
	mov	[filename_ptr], rax

	; введите x 
	mov	rdi, fmt_input_x
	xor	rax, rax
	call 	printf

	; ввод x
	mov	rdi, double
	mov	rsi, x
	xor	rax, rax
	call	scanf
	
	call	check_x
	; введите точность
	mov	rdi, fmt_input_eps
	xor	rax, rax
	call 	printf

	; ввод точности
	mov	rdi, double
	mov	rsi, eps
	xor	rax, rax
	call	scanf

	
	; открытие файла
	mov	rdi, [filename_ptr]
	mov	rsi, mode_write
	call	fopen
	test	rax, rax
	jz	.file_error
	mov	[file_handle], rax

	
	; arccos 1ым способом
	movsd	xmm0, [x]
	call	arccos_left_compute
	movsd	[rsp], xmm0
	
	; arccos 2ым способом
	call	compute_series

	
	mov	rdi, fmt_print_left	
	mov	rax, 1
	movsd	xmm0, [rsp]
	call	printf
	
	mov	rdi, fmt_print_right
	mov	rax, 1
	movsd	xmm0, [sum]
	call	printf


	mov	rdi, [file_handle]
	call	fclose
	
	xor	rax, rax
	leave
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
	fld1
	fld	qword [x]
	fabs		
	fcomip	st1	;St(1) = 1.0, St(0) = x
	ja	.error_x
	fstp	st0
	ret

.error_x:
	fstp	st0
	mov	rdi, invalid_x_msg
	xor	rax, rax
	call	printf
	mov	rdi, 1
	call	exit
	
	

arccos_left_compute:
	sub	rsp, 8
	movsd	[rsp], xmm0
	fld qword	[rsp] 	; загрузка в стек FPU значение x St(0) = x
	fld	st0		; St(1) = x, St(0) = x	
	fmul	st0, st0	; x * x = x^2. Результат в st0
	fld1			; St(0) = 1, St(1) = x^2, St(2) = x
	fsubrp	st1, st0	; St(0) = 1 - x^2, St(1) = x
	fsqrt			; St(0) = sqrt(1-x^2) 
	fxch	st1		; St(0) = x, St(1) = sqrt(1-x^2)
	fpatan			; St(0) = arctan(sqrt(1-x^2), x)
	fstp qword	[rsp]	; сохранить из стека
	movsd 	xmm0, [rsp]	
	add	rsp, 8		
	ret



compute_series:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48
	
	mov qword [n], 0
	pxor	xmm1, xmm1
	movsd	[sum], xmm1
	
	movsd	xmm0, [x]
	movsd	[rsp], xmm0	; сохран x

	pxor	xmm1, xmm1
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
	cvtsi2sd	xmm0, rax	;конвертит число в rax в число двойной точности и помещает в xmm0
	mulsd	xmm0, [rsp + 16]	;4^n * (2n + 1)
	mulsd	xmm0, [rsp + 24]	;4^n * (2n + 1) * (n!)^2

	movsd	xmm1, [rsp + 8]		; xmm1 = (2n)!
	divsd	xmm1, xmm0		; результат в первый операнд

	mov	rax, [n]
	add	rax, rax
	inc	rax			; rax = (2n + 1)
	call	pow_x			; xmm0 = x^(2n + 1)
	mulsd	xmm1, xmm0
	
	movsd	[term], xmm1
	

	movsd	xmm0, [term]
	call	fabs
	movsd	xmm1, [rsp + 40]	;rsp + 40 = eps
	comisd	xmm0, xmm1
	jb	.series_done
	
	
	;запись в файл
	call	fprintf_call

	;запись члена ряда
	movsd	xmm0, [sum]
	addsd	xmm0, [term]
	movsd	[sum], xmm0
	
	inc	qword [n]
	jmp	.series_loop

.series_done:
	movsd	xmm0, [sum]
	addsd	xmm0, [term]
	movsd	[sum], xmm0

	
	call	fprintf_call
	movsd	xmm0, [pi_value]
	subsd	xmm0, [sum]
	movsd	[sum], xmm0
	leave
	ret


fprintf_call:
	push	rbp
	mov	rbp, rsp

	mov     rdi, [file_handle]
        mov     rsi, fmt_file
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
	fld1			; St(0) = 1
	mov	rax, 1		

factorial_loop:
	cmp	rax, rcx
	jg	factorial_done
	push	rax
	fild	qword [rsp]	 ;загрузка целого из стека в FPU; St(0) = счетчик
	add	rsp, 8	
	fmulp	st1, st0	; St(1) = St(1) * St(0); Pop St(0)
	inc	rax	
	jmp	factorial_loop

factorial_done:
	sub	rsp, 8
	fstp	qword [rsp]	;St(0) = значение факториала
	movsd	xmm0, [rsp]	
	add	rsp, 8
	pop	rbp
	ret


factorial_n:
	push	rbp
	mov	rbp, rsp
	mov	rcx, rax
	fld1
	mov	rax, 1
	jmp	factorial_loop


pow_4n:
	push	rbp
	mov	rbp, rsp
	mov	rcx, rax	;rcx = n
	fld1			; St(0) = 1.0
	test	rcx, rcx
	jz	.p4n_done
	fld	qword	[four]	; St(0) = 4, St(1) = 1.0

.p4n_loop:
	test	rcx, rcx
	jz	.after_loop
	fmul	st1, st0
	dec	rcx
	jmp	.p4n_loop
	
.after_loop:
	fstp	st0	
	
.p4n_done:
	sub	rsp, 8
	fstp qword [rsp]
	movsd	xmm0, [rsp]
	add 	rsp, 8
	pop	rbp
	ret




pow_x:
	push	rbp
	mov	rbp, rsp
	fld1		; St(0) = 1.0
	test	rax, rax
	jz	.pow_done
	fld	qword [x] 	;St(1) = 1.0, St(0) = x

.pow_loop:
	test 	rax, rax
	jz	.after_loop
	fmul	st1, st0		;St(1) = результат; St(0) = x
	dec	rax
	jmp	.pow_loop

.after_loop:
	fstp	st0

.pow_done:
	sub rsp, 8
	fstp qword [rsp]
	movsd xmm0, [rsp]
	add rsp, 8
	pop	rbp
	ret




















