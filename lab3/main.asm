section .data

	vowels_up	db "AEIOUY", 0
	vowels_down 	db "aeiouy", 0

	system_read	equ 0	;rdi - file_descriptor, rsi - указатель на данные, rdx - количество байт для чтения
	system_write	equ 1	;по аналогии
	system_open	equ 2	
	system_close	equ 3
	system_break	equ 12
	system_exit 	equ 60

	asm_stdin	equ 0
	asm_stdout	equ 1
	asm_stderr	equ 2

	OPEN_FILE	equ 0
	BUFFER_SIZE	equ 4096
	MAX_WORD_SIZE	equ 1024

section .bss
	env_input_file	resq 1
	input_file	resd 1
	read_buf	resb BUFFER_SIZE
	output_buf	resb BUFFER_SIZE*2
	line__buf	resb BUFFER_SIZE

section .text
	global _start

;rdi - адрес строки
;rax - длина строки
asm_strlen:
	xor 	rax, rax
	mov 	rcx -1	
	cld		;чтоб RDI увеличивался
	repne 	scanb	;scanb берет из [RDI], сравнивает с al, ZF=1 если равны, RDI++
	not	rcx	
	dec	rcx	
	mov	rax, rcx
	ret


asm_print_errs:
	push	rdi
	call	asm_strlen
	pop	rsi
	mov	rdx, rax
	mov	rax, system_write
	mov	rdi, asm_stderr
	syscall
	ret


is_lowel:
	cmp	al, 'A'
	je	.set_vowel
	cmp	al, 'E'
	je	.set_vowel
	cmp     al, 'I'
	je      .set_vowel
	cmp	al, 'O'
	je      .set_vowel
	cmp	al, 'U'
	je      .set_vowel
	cmp 	al, 'Y'
	je	.set_vowel

	cmp	al, 'a'
	je      .set_vowel
	cmp	al, 'e'
	je      .set_vowel
	cmp	al, 'i'
	je      .set_vowel
	cmp	al, 'o'
	je	.set_vowel
	cmp	al, 'u'
	je	.set_vowel
	cmp	al, 'y'
	je	.set_vowel

	xor	rax, rax
	ret

.set_vowel:
	mov rax, 1
	ret

is_delim:
	cmp 	al, ' '
	je	.set_delim
	cmp	al, 9		;TAB
	je	.set_delim
	cmp	al, 10		;конец строки
	je	.set_delim
	cmp	al, 0		;0-терминал
	je	.set_delim
	
	xor rax, rax
	ret	

.set_delim:
	mov rax, 1
	ret


process_line:
	push	rbx
	push	rsi
	push	rcx
	push	r8
	push	r9
	push	r10
	
	mov	r8, output_buf	;Буффер
	mov	r9, rsi		;Текущая позиция
	mov	r10, rcx	;Ост. длина
	xor	rbx, rbx	;0 - вне слова, 1 - внутри слова


.process_char:
	cmp	r10, 0
	je	.finish_line
	
	mov 	al, [r9]
	
	call	is_delim
	cmp 	rax, 1
	je	.process_delim

	mov	al, [r9]
	call	.is_lowel

	cmp	rax, 1
	je	.duplicate_lowel

	mov	al, [r9]
	mov	[r8], al
	inc	r8
	jmp	.next_char

.duplicate_lowel:
	mov	al, [r9]
	mov	[r8], al
	inc	r8
	mov	[r8], al
	inc	r8
	jmp	.next_char

.process_delim:
	mov	al, [r9]
	mov	[r8], al
	inc	r8
	jmp	.next_char


.next_char:
	inc	r9
	dec	r10
	jmp	process_char


.finish_line:
	mov 	byte [r8], 0
	mov	rax, r8
	sub	rax, output_buf
	
	pop	r10
	pop	r9
	pop	r8
	pop	rcx
	pop	rsi
	pop	rbx
	ret


;СРЕДА ОКРУЖЕНИЯ ФУНКЦИИ
get_env_var:
	mov	rsi, [rsp]	;argc
	mov	rdx, [rsp + 8]	;argv
	lea	rdx, [rdx + 8]	;envp = argv + argc + 1
	mov	rsi, rdx
	
	call 	asm_strlen
	mov	rcx, rax

.search_env:
	mov	rsi, [rdx]
	test	rsi, rsi
	jz	.not_faund
	
	push	rcx	;длина строки переменной окружения
	push	rdi
	push	rsi

.compare_loop:
	mov	al, [rdi]
	mov	bl, [rsi]
	cmp	al, bl
	jne	.next_env
	test 	al, al
	jz	.check_equal
	inc	rdi
	inc	rsi
	jmp	.compare_loop

.check_equal:
	cmp	byte [rsi] '='
	jne	.next_env

	pop	rsi
	pop	rdi
	pop	rcx
	inc	rsi		;чтобы убрать "=" (было =text.txt, станет text.txt)
	mov	rax, rsi
	ret

.next_env:
	pop 	rsi
	pop	rdi
	pop	rcx
	add	rdx, 8
	jmp	.search_env


.not_found:
	xor	rax, rax
	ret

	



_start:
	mov	rdi, env_var_name
	call	get_env_var
	test	rax, rax
	jnz	.file_found



	
	




















