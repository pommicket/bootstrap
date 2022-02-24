# this file is necessary because tcc doesn't like musl's inline-assembly implementation
# of syscall
.global syscall0
.global syscall1
.global syscall2
.global syscall3
.global syscall4
.global syscall5
.global syscall6

syscall0:
syscall1:
syscall2:
syscall3:
syscall4:
syscall5:
syscall6:
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
	mov %rax, %rdi
	call __syscall_ret
	ret
