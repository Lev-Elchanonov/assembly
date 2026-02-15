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
        movsx r8, dword [a] ;a - адрес, [a] - значение по адресу
        movsx r9, dword [b] ;movsx - перемещение с расширением знака
        mov r10, qword [c]
        movsx r11, word [d]
        movsx r12, byte [e]

        mov rax, r8 ;поместили a в rax
        mov rbx, r9 ;поместили b в rdx

        add rbx, r10 ;(b+c) и результат в rbx
        imul rax, rbx ;a*(b+c) и результат в rax (imul умножает числа со знаком)

        mov r13, r12 ;временная копия e
        mov r14, r11 ;временная копия d (потом сюда положем результат)

        add r13, r8 ;(e+a) и результат в r13
        imul r14, r13 ;d*(e+a) и результат в r14

        sub rax, r14 ;a*(b+c) - d*(e+a) и результат в rax
        ;подсчитал числитель

        mov r13, r11 ;копируем d в r13
        imul r13, r13 ;находит d^2 и помещаем в r13
        mov rbx, r13 ;временно помещаем d^2 в rbx

        mov r14, r10 ;помещаем копию c в r14
        imul r14, r14 ;квадрат c^2 и поместил в r14

        imul r14, r9 ;c^2*b и результат в r14

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
