section .data
	err_no_env	db "Error: INPUT_FILE environment variable not set", 10, 0
	err_open_msg	db "Error: cannot open file", 10, 0
	err_read_msg	db "Error: cannot read file\n", 10, 0
	
	vowels_up	db "AEIOUY", 0
	vowels_down 	db "aeiouy", 0
	
	;equ = enum
	system_read	equ 0	;rdi - file_descriptor, rsi - указатель на данные, rdx - количество байт для чтения
	system_write	equ 1	;по аналогии
	system_open	equ 2	
	system_close	equ 3
	system_break	equ 12
	system_exit 	equ 60

	asm_stdin	equ 0
	asm_stdout	equ 1
	asm_stderr	equ 2

	OPEN_READONLY	equ 0
	BUFFER_SIZE	equ 5
	MAX_WORD_SIZE	equ 1024
	
	env_var_name    db "INPUT_FILE", 0

	saved_envp	dq 0
	
	one_space	db ' '
	new_line	db 10
section .bss
	input_file	resd 1
	read_buf	resb BUFFER_SIZE
	output_buf	resb BUFFER_SIZE*2
	leftover	resb MAX_WORD_SIZE
		

section .text
	global _start

;rdi - адрес строки
;rax - длина строки
asm_strlen:
	xor 	rax, rax
	mov 	rcx, -1	
	cld		;DF = 0
	repne 	scasb	;scanb берет из [RDI], сравнивает с al, ZF=1 если равны, RDI++
	not	rcx	
	dec	rcx	
	mov	rax, rcx
	ret


asm_print_err:
	push	rdi
	call	asm_strlen
	pop	rsi
	mov	rdx, rax
	mov	rax, system_write
	mov	rdi, asm_stderr
	syscall
	ret


is_vowel:
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
	cmp	al, 9
	je	.set_delim
	cmp	al, 10		;\n
	je	.set_delim
	
	xor rax, rax
	ret	

.set_delim:
	mov rax, 1
	ret


process_word:
	push	rbx
	push	rsi
	push	rcx
	push	r8
	push	r9
	
	mov	r8, rsi
	mov	r9, rcx		;ост. длина
	mov	rdi, output_buf
	xor	rbx, rbx	;длина слова


.process_loop:
	cmp	r9, 0
	je	.line_done
	
	
	mov	al, [r8]
	push	rax
	call	is_vowel
	cmp	rax, 1
	je	.duplicate_lowel

	pop	rax
	mov	[rdi], al
	inc	rdi
	inc	rbx
	
	jmp	.next

.duplicate_lowel:
	pop	rax
	mov	al, [r8]
	mov	[rdi], al
	inc	rdi
	mov	[rdi], al
	inc	rdi
	add	rbx, 2

.next:
	inc	r8
	dec	r9
	jmp	.process_loop

.line_done:
	mov	rax, rbx
	pop	r9
	pop	r8
	pop	rcx
	pop	rsi
	pop	rbx
	ret

;sys_write(file_descriptor(RDI), buf(RSI), count(RDX))
flush_output:
	test	rcx, rcx
	jz	.done
	
	mov	rax, system_write
	mov	rdi, asm_stdout
	mov	rdx, rcx
	syscall
.done:
	ret


;СРЕДА ОКРУЖЕНИЯ ФУНКЦИИ
get_env_var:
	mov	rdx, [saved_envp]

	push	rdi	
	call 	asm_strlen
	pop	rdi
	mov	rcx, rax

.search_env:
	mov	rsi, [rdx]
	test	rsi, rsi
	jz	.not_found	;если envp = NULL
	
	push	rcx	;длина строки переменной окружения
	push	rdi
	push	rsi

.compare_loop:
	mov	al, [rdi]
	test	al, al		;проверка на конец строки
	jz	.check_equal

	mov	bl, [rsi]
	cmp	al, bl
	jne	.next_env

	inc	rdi
	inc	rsi
	jmp	.compare_loop

.check_equal:
	cmp	byte [rsi], '='
	jne	.next_env
	mov	rax, rsi

	pop	rsi
	pop	rdi
	pop	rcx
	inc	rax		;чтобы убрать "=" (было =text.txt, станет text.txt)
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

	


;rax - результат сис	колов
;rdi - аргумент для get_env_var, system_open, system write
;r12 - длина остатка от предидущего буфера
;r13 - 0 - вне слова, 1 - внутри слова
;r15 - кол-во прочитанных байт
;rbx - индекс в бфере read_buf
_start:	
	mov	rdx, [rsp]
	lea	rcx, [rsp + 8*(rdx + 2)]	
	mov	[saved_envp], rcx
	
	mov	rdi, env_var_name
	call	get_env_var
	test	rax, rax
	jnz	.file_found	;rax !=0 - файл найден



	mov	rdi, err_no_env
	call	asm_print_err
	mov	rax, system_exit
	mov	rdi, 1
	syscall	

;sys_open(fd(RDI), ORDONLY(RSI), права доступа (rdx))
.file_found:
	mov	rsi, OPEN_READONLY	;=0, только на чтение
	mov	rdx, 0			;без прав доступа (используется только в CREATE когда создается новый файл)
 	mov	rdi, rax		;rax = чтото.txt
	mov	rax, system_open
	syscall				;открыли файл
	
	test	rax, rax
	js	.open_error
	
	mov	[input_file], eax 	;сохр дескриптор
			
	mov	r12, 0			;длина остатка от пред. буффера
	mov	r13, 0			;0 - вне слова
	mov	r14, 0			;счетчик входного буффера

;цикл чтения
;sys_read(fd (RDI), buf (RSI), count (RDX))
.read_loop:
	mov	rax, system_read
	mov	rdi, [input_file] 
	mov	rsi, read_buf		
	mov	rdx, BUFFER_SIZE
	syscall				;читаем
	
	test	rax, rax	;проверка кол-ва прочитанных байт
	js	.read_error	
	jz	.eof		

	mov	r15, rax	;сколько байт прочитали
	mov	rbx, 0		;индекс в буфере
	
	;остаток из пред. буффера
	cmp	r12, 0
	je	.process_buffer	
	
	mov	rsi, leftover	;указатель на буф. остатка
	mov	rcx, r12	;длина остатка
	call	process_word
	
	push	rbx
	push	r12
	push	r13
	push	r14
	push	r15
	
	mov	rsi, output_buf
	mov	rcx, rax	;количество символов
	call 	flush_output	;вывод на экран

	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbx
	
	;обработка пробела если слово на стыке буфера
	mov	rax, [read_buf + rbx]
	call	is_delim
	cmp	rax, 1
	jne	.process_buffer
	
	
	push 	rax
	push	rdi
	push	rsi
	push	rdx
	
	mov     rax, system_write
	mov     rdi, asm_stdout
	mov     rsi, one_space
	mov     rdx, 1
	syscall
	
	pop	rdx
	pop	rsi	
	pop	rdi	
	pop	rax
.process_buffer:
	xor	r12, r12	;сброс остатка
	mov	rsi, read_buf
	add	rsi, rbx	;текущая позиция в буффере
	mov	rcx, r15
	sub	rcx, rbx	;осталось обработать байт

	xor	r9, r9
	mov	r10, rbx	;текущий индекс
	
.scan_loop:
	cmp	rbx, r15
	jge	.end_of_buffer	;дошли до конца буффера
	
	mov	al, [read_buf + rbx]
	push	rax
	call	is_delim
	cmp	rax, 1		;символ разделитель
	je	.delim_found

	;обработка слова
	pop	rax
	cmp	r9, 0
	jne	.continue_word
	mov	r10, rbx

.continue_word:
	inc	r9		;длина слова + 1
	inc	rbx		;переход к некст символу
	jmp	.scan_loop

;r9 - длина слова
.delim_found:
	pop	rax
	cmp	r9, 0
	je	.delim_process	;если слова до этого не было
	
	push	rbx
	push	rcx
	push	rsi
	push	rdi	
	push	r8
	push	r9
	push	r10
	push	rax
	
	mov	rsi, read_buf
	add	rsi, r10	;начало словаа
	mov	rcx, r9		;его длина
	call	process_word	

	mov	rsi, output_buf
	mov	rcx, rax	
	call	flush_output
	
	pop	rax
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	
	mov	r9, 0
	mov	r13, 1		;пометка что после вывода слова
	cmp	al, 10
	je	.write_nextline
	
	mov	rax, system_write
	mov 	rdi, asm_stdout
	mov	rsi, one_space
	mov	rdx, 1
	syscall

.delim_process:
	cmp	al, 10
	je	.write_nextline

	jmp	.skip_delim

.write_nextline:
	mov	rax, system_write
	mov	rdi, asm_stdout
	mov	rsi, new_line
	mov	rdx, 1
	mov 	r13, 0
	syscall

.skip_delim:
	inc	rbx
	jmp	.scan_loop

.end_of_buffer:
	cmp	r9, 0		;есть ли незавершенное слово
	je	.no_leftover	
	
	;данные об остатке
	mov	r12, r9		;r9 - длина слова
	mov	rsi, read_buf
	add	rsi, r10
	mov	rdi, leftover
	mov	rcx, r9
	cld	
	rep 	movsb		;копируем байты из rsi в rdi (leftover)
	jmp	.read_loop

.no_leftover:
	jmp	.read_loop

.eof:
	cmp	r12, 0
	je	.close_file
	
	mov	rsi, leftover
	mov	rcx, r12
	call	process_word

	mov	rsi, output_buf
	mov	rcx, rax
	call	flush_output

.close_file:
	mov	rax, system_close
	mov	rdi, [input_file]
	syscall

	mov	rax, system_exit
	xor	rdi, rdi
	syscall

.open_error:
	mov	rdi, err_open_msg
	call	asm_print_err
	mov	rax, system_exit
	mov	rdi, 1
	syscall

.read_error:
	mov	rdi, err_read_msg
	call	asm_print_err
	mov	rax, system_exit
	mov	rdi, 1
	syscall



	

