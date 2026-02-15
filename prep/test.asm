section .text
	global _start
_start:
	mov r8, 60
	mov rdx, r8
	
	mov rax, 60
	mov rdi, 0
	syscall
	
