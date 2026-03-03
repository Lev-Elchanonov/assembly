section .data
	matrix_cals:	db 3
	matrix_rows: 	db 4

	maxrix:		db 5, 2, 9, 1
			db -3, 7, -1, 4
			db 8. 0. -5, 6
	
	sort_direction: 0

section .text
	global: _start

_start:
	mov 	rsi, matrix		;rsi это адрес начала матрицы
	movzx	rcx, [matrix_rows]	;занулили rcx перед тем как положить количество строк

;ГЛАВАЯ СЕКЦИЯ ПЕРЕХОДА ПО СТРОКАМ	
row_loop:
	push	 rcx			;сохранили количество строк
	push	 rsi			;сохранили адрес нначала матрицы
	
	mov	 rdi, rsi		;rdi - адрес текущей строки)
	mov	 rdx, [matrix_cols]	;rdx - длина строки
	
	call	 heap_sort

	pop 	rsi			;возвращаем инфу о началаа матрицы
	movzx	rax, [matrix_cols]	;rax - длина строки
	add	rsi, rax		;rsi укзывает теперь на следующую сточку

	pop	rcx			;восстановили счетчик строк

	dec	rcx			;уменьшаем счетчик строк на 1
	jnz	row_loop		;если !=0 то повторяем цикл, а если 0, то все строки пройдены
	
	mov	rax, 60
	xor	rdi, rdi
	syscall


heap_sort:
	push 	rbx
	push	r12
	push	r13
	
	mov 	r12, rdi		;r12 содержит инфу о текущей строки
	mov	r13, rdx		;адрес длины строки

	mov 	rbx, r13
	shr	rbx			;rbx = n/2 
	dec	rbx			;rbx = n/2 - 1 - узнали верхушку

build_heap:
	cmp 	rbx, 0			
	jl	sort_start		;если rbx < 0, то мы просмотрели все родительские узлы, а значит можно перейти к сортировке
	
	mov	rdi, r12
	mov	rsi, rbx
	mov	rdx, r13
	call 	heapify


	dec 	rbx			;переходим к след. родительскому узлу
	jmp	build_heap		;начинаем процедуру построения кучи для нового родительского узла
