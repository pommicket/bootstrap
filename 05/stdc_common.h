#ifndef _STDC_COMMON_H
#define _STDC_COMMON_H

#ifdef _STDLIB_DEBUG
int printf(char *);
#endif


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

#define INT8_MAX    0x7f
#define INT8_MIN  (-0x80)
#define INT16_MAX   0x7fff
#define INT16_MIN (-0x8000)
#define INT32_MAX   0x7fffffff
#define INT32_MIN (-0x80000000)
#define INT64_MAX   0x7fffffffffffffff
#define INT64_MIN (-0x8000000000000000)
#define UINT8_MAX   0xff
#define UINT16_MAX  0xffff
#define UINT32_MAX  0xffffffff
#define UINT64_MAX  0xffffffffffffffff
#define CHAR_BIT 8
#define MB_LEN_MAX 4
#define CHAR_MIN INT8_MIN
#define CHAR_MAX INT8_MAX
#define SCHAR_MIN INT8_MIN
#define SCHAR_MAX INT8_MAX
#define INT_MIN INT32_MIN
#define INT_MAX INT32_MAX
#define LONG_MIN INT64_MIN
#define LONG_MAX INT64_MAX
#define SHRT_MIN INT16_MIN
#define SHRT_MAX INT16_MAX
#define UCHAR_MAX UINT8_MAX
#define USHRT_MAX UINT16_MAX
#define UINT_MAX UINT32_MAX
#define ULONG_MAX UINT64_MAX

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

int isspace(int c) {
	return c == ' ' || c == '\f' || c == '\n' || c == '\r' || c == '\t' || c == '\v';
}

unsigned long strtoul(const char *nptr, char **endptr, int base) {
	unsigned long value = 0, newvalue;
	int overflow = 0;
	
	while (isspace(*nptr)) ++nptr;
	if (*nptr == '+') ++nptr;
	if (base == 0) {
		if (*nptr == '0') {
			++nptr;
			switch (*nptr) {
			case 'x':
			case 'X':
				base = 16;
				++nptr;
				break;
			case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7':
				base = 8;
				break;
			default:
				// this must just be the number 0.
				if (endptr) *endptr = nptr;
				return 0;
			}
		} else {
			base = 10;
		}
	}
		
	while (1) {
		int c = *nptr;
		unsigned v;
		if (c >= '0' && c <= '9')
			v = c - '0';
		else if (c >= 'a' && c <= 'z')
			v = c - 'a' + 10;
		else if (c >= 'A' && c <= 'Z')
			v = c - 'A' + 10;
		else break;
		if (v >= base) break;
		unsigned long newvalue = value * base + v;
		if (newvalue < value) overflow = 1;
		value = newvalue;
		++nptr;
	}
	*endptr = nptr;
	if (overflow) {
		errno = ERANGE;
		return ULONG_MAX;
	} else {
		return value;
	}
}

long strtol(const char *nptr, char **endptr, int base) {
	int sign = 1;
	while (isspace(*nptr)) ++nptr;
	if (*nptr == '-') {
		sign = -1;
		++nptr;
	}
	unsigned long mag = strtoul(nptr, endptr, base);
	if (sign > 0) {
		if (mag > LONG_MAX) {
			errno = ERANGE;
			return LONG_MIN;
		}
		return (long)mag;
	} else {
		if (mag > (unsigned long)LONG_MAX + 1) {
			errno = ERANGE;
			return LONG_MIN;
		}
		return -(long)mag;
	}
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
