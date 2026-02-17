section .data
	a: dd -5 	;dd = define dword
	b: dd 3
	c: dq 2 	;dq = define qword
	d: dw 4 	;dw = define word
	e: db 1 	;db = define byte

	res: dq 0
	rem: dq 0
section .text
	global _start
_start:
	mov r8d, [a] 	;a - адрес, [a] - значение по адресу
	mov r9d, [b]
	mov r10, [c]
	mov r11w, [d]
	mov r12b, [e]

	movsx rax, r8d	;поместили a в rax (расширили, чтобы потом умножить)
	movsx rbx, r9d	;поместили b в rbx (расширили, чтобы потом сложить)
	
	add rbx, r10 	;(b+c) и результат в rbx
	jo _error	;перескок если переполнение
	imul rax, rbx 	;a*(b+c) и результат в rax (imul умножает числа со знаком). Если возникло переполнение, то оно уйдет в rdx
	jo _error	;перескок если переполнение
		
	movsx r13d, r12b ;временная копия e (расширяем до a для послед. сложения)
	movsx r14, r11w ;временная копия d (потом сюда положем результат умножения)
	
	add r13d, r8d 	;(e+a) и результат в r13d
	jo _error
	movsx r13, r13d ;расширили для послед умножения + вычитания
	imul r14, r13 	;d*(e+a) и результат в r14
	jo _error
	
	sub rax, r14 	;a*(b+c) - d*(e+a) и результат в rax
	jo _error
	;подсчитал числитель



	movsx rbx, r11w ;копируем d в rbx с расширением для посл. вычитания
	imul rbx, rbx 	;находит d^2 и помещаем в rbx
	jo _error

	mov r14, r10 	;помещаем копию c в r14
	imul r14, r14 	;квадрат c^2 и поместил в r14
	jo _error
		
	movsx r13, r9d 	;расширяем b для послед. умножения
	imul r14, r13 	;c^2*b и результат в r14
	jo _error

	sub rbx, r14 	;d^2 - c^2*b и результат в rbx
	jo _error
	;посчитал знаменатель
	

	cmp rbx, 0 	;сравнение
	je _error	;jump if equal перескок на метку devision_zero (флаг ZF если равенство)
	
	cqo 		;мы не можем делить 64 разр на 64 разр. Надо расширить rax до 8х слова в RDX:RAX
	idiv rbx 	;делим на знаменатель. Частное будет в RAX, а остаток в RDX
	
	mov [res], rdx 	;запись в значение по адресу result
	mov [rem], rax 	;запись в значение по адресу remainder
	
	mov rax, 60 	;exit
	xor rdi, rdi
	syscall

_error:
	mov rax, 60
	mov rdi, 1 	;код ошибки 1
	syscall
