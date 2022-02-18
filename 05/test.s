.global _start
.global __syscall

__syscall:
	# SysV calling convention:          RDI, RSI, RDX, RCX, R8,  R9, 8(%rsp)
	# Linux syscall calling convention: RAX, RDI, RSI, RDX, R10, R8, R9
	mov %rdi, %rax
	mov %rsi, %rdi
	mov %rdx, %rsi
	mov %rcx, %rdx
	mov %r8, %r10
	mov %r9, %r8
	mov 8(%rsp), %r9
	syscall
	ret
	
_start:
	lea __syscall, %rdi
	call main
	mov $60, %eax
	syscall
