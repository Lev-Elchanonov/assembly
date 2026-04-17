section .data
	fmt_input_x db "Enter x (|x|<=1): ", 0
	fmt_input_eps db "Enter precision: ", 0
	double db "%lf", 0
	fmt_print_left db "Left side (arccos): %.10f", 10, 0
	fmt_print_right db "Right side (arccos): %.10f", 10, 0
	fmt_file db "n = %d, term = %.10f", 10, 0
	err_msg db "Error: cant open file", 10, 0
	pi_value dq 1.5707963267948966

section .bss
	x resq 1
	eps resq 1
	term resq 1
	sum resq 1
	factorial_pars resq 1
	file_handle resq 1
	n resq 1
	filename_ptr resq 1

section .text
	extern printf, scanf, fopen, fprintf, fclose, exit, pow, fabs
	global main

main:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 16

	cmp	edi, 2
	jne	.usage
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
	mov	rsi, 119 ; w mode
	call	fopen
	test	rax, rax
	jz	.file_error
	mov	[file_handle], rax

	
	; arccos 1ым способом
	movsd	xmm0, [x]
	call	arccos_left_compute
	push	xmm0
	
	; arccos 2ым способом
	call	compute_series

	
	mov	rdi, fmt_print_left	
	mov	rax, 1
	pop	xmm0
	call	printf
	
	mov	rdi, fmt_printf_left
	mov	rax, 1
	movsd	xmm0, [sum]
	call	printf


	mov	rdi, [file_handler]
	call	fclose
	
	xor	rax, rax
	leave
	ret

.usage:
	mov	rdi, 1
	call	exit

.file_error:
	mov	rdi, err_msg
	xor	rax, rax
	call	printf
	mov 	rdi, 1
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




























