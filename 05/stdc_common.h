#ifndef _STDC_COMMON_H
#define _STDC_COMMON_H

#define signed
#define volatile
#define register
#define const
#define NULL ((void*)0)

typedef unsigned char  uint8_t;
typedef char           int8_t;
typedef unsigned short uint16_t;
typedef short          int16_t;
typedef unsigned int   uint32_t;
typedef int            int32_t;
typedef unsigned long  uint64_t;
typedef long           int64_t;
typedef unsigned long  size_t;
typedef long           ptrdiff_t;
typedef unsigned long  uintptr_t;
typedef long           intptr_t;

static unsigned char __syscall_data[] = {
	// mov rax, [rsp+24]
	0x48, 0x8b, 0x84, 0x24, 24, 0, 0, 0,
	// mov rdi, rax
	0x48, 0x89, 0xc7,
	// mov rax, [rsp+32]
	0x48, 0x8b, 0x84, 0x24, 32, 0, 0, 0,
	// mov rsi, rax
	0x48, 0x89, 0xc6,
	// mov rax, [rsp+40]
	0x48, 0x8b, 0x84, 0x24, 40, 0, 0, 0,
	// mov rdx, rax
	0x48, 0x89, 0xc2,
	// mov rax, [rsp+48]
	0x48, 0x8b, 0x84, 0x24, 48, 0, 0, 0,
	// mov r10, rax
	0x49, 0x89, 0xc2,
	// mov rax, [rsp+56]
	0x48, 0x8b, 0x84, 0x24, 56, 0, 0, 0,
	// mov r8, rax
	0x49, 0x89, 0xc0,
	// mov rax, [rsp+64]
	0x48, 0x8b, 0x84, 0x24, 64, 0, 0, 0,
	// mov r9, rax
	0x49, 0x89, 0xc1,
	// mov rax, [rsp+16]
	0x48, 0x8b, 0x84, 0x24, 16, 0, 0, 0,
	// syscall
	0x0f, 0x05,
	// mov [rsp+8], rax
	0x48, 0x89, 0x84, 0x24, 8, 0, 0, 0,
	// ret
	0xc3
};

#define __syscall(no, arg1, arg2, arg3, arg4, arg5, arg6)\
	(((unsigned long (*)(unsigned long, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long))__syscall_data)\
		(no, arg1, arg2, arg3, arg4, arg5, arg6))

long read(int fd, void *buf, size_t count) {
	return __syscall(0, fd, buf, count, 0, 0, 0);
}

long write(int fd, void *buf, size_t count) {
	return __syscall(1, fd, buf, count, 0, 0, 0);
}

void _Exit(int status) {
	return __syscall(60, status, 0, 0, 0, 0, 0);
}

typedef long time_t;

struct timespec {
	time_t tv_sec;
	long tv_nsec;
};

#define CLOCK_REALTIME 0
#define CLOCK_MONOTONIC 1
int clock_gettime(int clock, struct timespec *tp) {
	return __syscall(228, clock, tp, 0, 0, 0, 0);
}

#define F_OK 0
#define R_OK 4
#define W_OK 2
#define X_OK 1
int access(const char *pathname, int mode) {
	return __syscall(21, pathname, mode, 0, 0, 0, 0);
}


int errno;

#define EIO 5
#define EDOM 33
#define ERANGE 34

#define PROT_READ 1
#define PROT_WRITE 2
#define PROT_EXEC 4
#define MAP_SHARED 0x01
#define MAP_ANONYMOUS 0x20
#define MAP_PRIVATE 0x02
void *mmap(void *addr, size_t length, int prot, int flags, int fd, long offset) {
	return __syscall(9, addr, length, prot, flags, fd, offset);
}

int munmap(void *addr, size_t length) {
	return __syscall(11, addr, length, 0, 0, 0, 0);
}

void *malloc(size_t n) {
	void *memory;
	size_t bytes = n + 16;
	memory = mmap(0, bytes, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, -1, 0);
	if ((uint64_t)memory > 0xffffffffffff0000) return NULL;
	*(uint64_t *)memory = bytes;
	return (char *)memory + 16;
}

void free(void *ptr) {
	uint64_t *memory = (char *)ptr - 16;
	uint64_t size = *memory;
	munmap(memory, size);
}

void *calloc(size_t nmemb, size_t size) {
	if (nmemb > 0xffffffffffffffff / size)
		return NULL;
	return malloc(nmemb * size);
}


size_t strlen(char *s) {
	char *t = s;
	while (*t) ++t;
	return t - s;
}


typedef struct {
	int fd;
	unsigned char eof;
	unsigned char err;
} FILE;

FILE _stdin = {0}, *stdin;
FILE _stdout = {1}, *stdout;
FILE _stderr = {2}, *stderr;

int main();

int _main(int argc, char **argv) {
	stdin = &_stdin;
	stdout = &_stdout;
	stderr = &_stderr;
	return main(argc, argv);
}


#endif // _STDC_COMMON_H
