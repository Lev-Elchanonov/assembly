section .data
	a: dd -5 ;dd = define dword
	b: dd 3
	c: dq 2 ;dq = define qword
	d: dw 4 ;dw = define word
	e: db 1 ;db = define byte

	result: dq 0
	remainder: dq 0
section .text
	global _start
_start:
	mov r8d, [a] ;a - адрес, [a] - значение по адресу
	mov r9d, [b]
	mov r10, [c]
	mov r11w, [d]
	mov r12b, [e]

	mov eax, r8d ;поместили a в eax
	mov ebx, r9d ;поместили b в ebx
	
	movsx rbx, ebx ;расширяем eax с сохранением знака для последующего сложения
	add rbx, r10 ;(b+c) и результат в rbx
	movsx rax, eax ;расширяем eax (лежит a) для последующего умножения
	imul rax, rbx ;a*(b+c) и результат в rax (imul умножает числа со знаком)
	
	mov r13b, r12b ;временная копия e
	mov r14w, r11w ;временная копия d (потом сюда положем результат)
	
	movsx r13, r13b ;расширяем e до размера a*2
	movsx r15, r8d ;копируем a расширением 64 в r15
	add r13, r15 ;(e+a) и результат в r13
	movsx r14, r14w ;расширили d до qword для послед умножения
	imul r14, r13 ;d*(e+a) и результат в r14d

	sub rax, r14 ;a*(b+c) - d*(e+a) и результат в rax
	;подсчитал числитель



	movsx r13, r11w ;копируем d в r13 с расширением для посл. вычитания
	imul r13, r13 ;находит d^2 и помещаем в r13
	mov rbx, r13 ;временно помещаем d^2 в rbx
	
	mov r14, r10 ;помещаем копию c в r14
	imul r14, r14 ;квадрат c^2 и поместил в r14
	
	movsx r15, r9d ;расширяем b для послед. умножения
	imul r14, r15 ;c^2*b и результат в r14

	sub rbx, r14 ;d^2 - c^2*b и результат в rbx 
	;посчитал знаменатель
	
	cmp rbx, 0 ;сравнение 
	je zero_devision ;jump if equal перескок на метку devision_zero (флаг ZF если равенство)
	
	cqo ;мы не можем делить 64 разр на 64 разр. Надо расширить rax до 8х слова в RDX:RAX
	idiv rbx ;делим на знаменатель. Частное будет в RAX, а остаток в RDX
	
	mov [result], rdx ;запись в значение по адресу result
	mov [remainder], rax ;запись в значение по адресу remainder
	
	mov rax, 60 ;exit
	xor rdi, rdi
	syscall

zero_devision:
	mov rax, 60
	mov rdi, 1 ;код ошибки 1(деление на 0)
	syscall
