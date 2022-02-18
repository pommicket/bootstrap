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

// we need to define ucontext_t
# define __ctx(fld) fld
typedef long long int greg_t;
#define __NGREG	23
typedef greg_t gregset_t[__NGREG];
#define _SIGSET_NWORDS (1024 / (8 * sizeof (unsigned long int)))
typedef struct
{
  unsigned long int __val[_SIGSET_NWORDS];
} __sigset_t, sigset_t;
typedef struct
{
	void *ss_sp;
	int ss_flags;
	size_t ss_size;
} stack_t;
enum
{
  REG_R8 = 0,
# define REG_R8		REG_R8
  REG_R9,
# define REG_R9		REG_R9
  REG_R10,
# define REG_R10	REG_R10
  REG_R11,
# define REG_R11	REG_R11
  REG_R12,
# define REG_R12	REG_R12
  REG_R13,
# define REG_R13	REG_R13
  REG_R14,
# define REG_R14	REG_R14
  REG_R15,
# define REG_R15	REG_R15
  REG_RDI,
# define REG_RDI	REG_RDI
  REG_RSI,
# define REG_RSI	REG_RSI
  REG_RBP,
# define REG_RBP	REG_RBP
  REG_RBX,
# define REG_RBX	REG_RBX
  REG_RDX,
# define REG_RDX	REG_RDX
  REG_RAX,
# define REG_RAX	REG_RAX
  REG_RCX,
# define REG_RCX	REG_RCX
  REG_RSP,
# define REG_RSP	REG_RSP
  REG_RIP,
# define REG_RIP	REG_RIP
  REG_EFL,
# define REG_EFL	REG_EFL
  REG_CSGSFS,		/* Actually short cs, gs, fs, __pad0.  */
# define REG_CSGSFS	REG_CSGSFS
  REG_ERR,
# define REG_ERR	REG_ERR
  REG_TRAPNO,
# define REG_TRAPNO	REG_TRAPNO
  REG_OLDMASK,
# define REG_OLDMASK	REG_OLDMASK
  REG_CR2
# define REG_CR2	REG_CR2
};
struct _libc_fpxreg
{
  unsigned short int __ctx(significand)[4];
  unsigned short int __ctx(exponent);
  unsigned short int __glibc_reserved1[3];
};
struct _libc_xmmreg
{
	uint32_t	__ctx(element)[4];
};
struct _libc_fpstate
{
	uint16_t		__ctx(cwd);
	uint16_t		__ctx(swd);
	uint16_t		__ctx(ftw);
	uint16_t		__ctx(fop);
	uint64_t		__ctx(rip);
	uint64_t		__ctx(rdp);
	uint32_t		__ctx(mxcsr);
	uint32_t		__ctx(mxcr_mask);
	struct _libc_fpxreg	_st[8];
	struct _libc_xmmreg	_xmm[16];
	uint32_t		__glibc_reserved1[24];
};
typedef struct _libc_fpstate *fpregset_t;
typedef struct {
	gregset_t __ctx(gregs);
	fpregset_t __ctx(fpregs);
	unsigned long long __reserved1 [8];
} mcontext_t;
typedef struct ucontext_t {
	unsigned long int __ctx(uc_flags);
	struct ucontext_t *uc_link;
	stack_t uc_stack;
	mcontext_t uc_mcontext;
	sigset_t uc_sigmask;
	struct _libc_fpstate __fpregs_mem;
	unsigned long long int __ssp[4];
} ucontext_t;

long read(int fd, void *buf, size_t count) {
	return __syscall(0, fd, buf, count, 0, 0, 0);
}

long write(int fd, void *buf, size_t count) {
	return __syscall(1, fd, buf, count, 0, 0, 0);
}

void _Exit(int status) {
	return __syscall(60, status, 0, 0, 0, 0, 0);
}

int kill(int pid, int sig) {
	return __syscall(62, pid, sig, 0, 0, 0, 0);
}

int getpid(void) {
	return __syscall(39, 0, 0, 0, 0, 0, 0);
}

int fork(void) {
	return __syscall(57, 0, 0, 0, 0, 0, 0);
}

int execve(const char *pathname, char *const argv[], char *const envp[]) {
	return __syscall(59, pathname, argv, envp, 0, 0, 0);
}

int gettimeofday(struct timeval *tv, struct timezone *tz) {
	return __syscall(96, tv, tz, 0, 0, 0, 0);
}

typedef long time_t;

struct timespec {
	time_t tv_sec;
	long tv_nsec;
};

struct timeval {
	time_t tv_sec;
	long tv_usec;
};

struct timezone {
	int tz_minuteswest;
	int tz_dsttime;
};

char *getcwd(char *buf, size_t size) {
	long n = __syscall(79, buf, size, 0, 0, 0, 0);
	if (n < 0) return NULL;
	return buf;
}

#define _WEXITSTATUS(status)   (((status) & 0xff00) >> 8)
#define _WIFEXITED(status) (__WTERMSIG(status) == 0)
#define _WIFSIGNALED(status) \
  (((signed char) (((status) & 0x7f) + 1) >> 1) > 0)
int wait4(int pid, int *status, int options, struct rusage *rusage) {
	return __syscall(61, pid, status, options, rusage, 0, 0);
}

#define SIGABRT 6
#define SIGFPE 8
#define SIGKILL 9
#define SIGILL 4
#define SIGINT 2
#define SIGSEGV 11
#define SIGTERM 15
#define SIGBUS 7
#define SIGTRAP 5
void abort(void) {
	kill(getpid(), SIGABRT);
}


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

typedef struct {
	int fd;
	unsigned char eof;
	unsigned char err;
	unsigned char has_ungetc;
	char ungetc; // character which was pushed by ungetc()
} FILE;

int errno;
int printf(char *, ...);
int fprintf(FILE *, char *, ...); // needed now for assert()

FILE _stdin = {0}, *stdin;
FILE _stdout = {1}, *stdout;
FILE _stderr = {2}, *stderr;

#ifdef NDEBUG
#define assert(x) ((void)0)
#else
int __assert_failed(const char *file, int line, const char *expr) {
	fprintf(stderr, "Assertion failed at %s:%d: %s\n", file, line, expr);
	abort();
}
#define assert(x) (void)((x) || __assert_failed(__FILE__, __LINE__, #x))
#endif


int _clamp_long_to_int(long x) {
	if (x < INT_MIN) return INT_MIN;
	if (x > INT_MAX) return INT_MAX;
	return x;
}

short _clamp_long_to_short(long x) {
	if (x < SHRT_MIN) return SHRT_MIN;
	if (x > SHRT_MAX) return SHRT_MAX;
	return x;
}

unsigned _clamp_ulong_to_uint(unsigned long x) {
	if (x > UINT_MAX) return UINT_MAX;
	return x;
}

unsigned short _clamp_ulong_to_ushort(unsigned long x) {
	if (x > USHRT_MAX) return USHRT_MAX;
	return x;
}

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

int mprotect(void *addr, size_t len, int prot) {
	return __syscall(10, addr, len, prot, 0, 0, 0);
}

#define MREMAP_MAYMOVE 1
void *_mremap(void *addr, size_t old_size, size_t new_size, int flags) {
	return __syscall(25, addr, old_size, new_size, flags, 0, 0);
}

void *malloc(size_t n) {
	if (!n) return NULL;
	void *memory;
	size_t bytes = n + 16;
	memory = mmap(0, bytes, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, -1, 0);
	if ((uint64_t)memory > 0xffffffffffff0000) return NULL;
	*(uint64_t *)memory = bytes;
	return (char *)memory + 16;
}

void free(void *ptr) {
	if (!ptr) return;
	uint64_t *memory = (char *)ptr - 16;
	uint64_t size = *memory;
	munmap(memory, size);
}


size_t strlen(char *s) {
	char *t = s;
	while (*t) ++t;
	return t - s;
}

void *memcpy(void *s1, const void *s2, size_t n) {
	char *p = s1, *end = p + n, *q = s2;
	while (p < end)
		*p++ = *q++;
	return s1;
}

int isspace(int c) {
	return c == ' ' || c == '\f' || c == '\n' || c == '\r' || c == '\t' || c == '\v';
}

int isdigit(int c) {
	return c >= '0' && c <= '9';
}

int _isdigit_in_base(int c, int base) {
	if (c >= '0' && c <= '9') {
		return c - '0' < base;
	} else if (c >= 'a' && c <= 'z') {
		return c - 'a' + 10 < base;
	} else if (c >= 'A' && c <= 'Z') {
		return c - 'A' + 10 < base;
	}
	return 0;
}

void *memset(void *s, int c, size_t n) {
	char *p = s, *end = p + n;
	while (p < end)
		*p++ = c;
	return s;
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
	if (endptr) *endptr = nptr;
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
			return LONG_MAX;
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

long _strtol_clamped(const char *nptr, char **endptr, int base, int min, int max) {
	long l = strtol(nptr, endptr, base);
	if (l < min) return min;
	if (l > max) return max;
	return l;
}

#define _NPOW10 310
#define _INFINITY 1e1000
// non-negative floating-point number with more precision than a double
//  its value is equal to fraction * 2^exponent
typedef struct {
	unsigned long fraction;
	int exponent;
} _Float;

// ensure that f->fraction >= 2^64 / 2
static void _normalize_float(_Float *f) {
	if (!f->fraction) return;
	while (f->fraction < 0x8000000000000000) {
		f->exponent -= 1;
		f->fraction <<= 1;
	}
}

static double _Float_to_double(_Float f) {
	unsigned long dbl_fraction;
	int dbl_exponent;
	unsigned long dbl_value;
	if (f.fraction == 0) return 0;
	_normalize_float(&f);
	f.fraction &= 0x7fffffffffffffff; // remove the "1." in 1.01101110111... to get 63-bit significand
	dbl_fraction = (f.fraction + 0x3ff) >> 11;
	dbl_exponent = f.exponent + 63;
	if (dbl_exponent < -1022) return 0;
	if (dbl_exponent >  1023) return _INFINITY;
	dbl_exponent += 1023;
	dbl_value = (unsigned long)dbl_exponent << 52 | dbl_fraction;
	return *(double *)&dbl_value;
}

static _Float _powers_of_10_dat[2*_NPOW10+1];
static _Float *_powers_of_10;
static _Float _Float_ZERO = {0, 1};
static _Float _Float_INFINITY = {0x8000000000000000, 100000};


_Float _int_pow10(int x) {
	if (x <= -_NPOW10) return _Float_ZERO;
	if (x >= _NPOW10) return _Float_INFINITY;
	return _powers_of_10[x];
}

double strtod(const char *nptr, char **endptr) {
	const char *flt, *dot, *p, *number_end;
	double sign = 1;
	int exponent = 0;
	while (isspace(*nptr)) ++nptr;
	
	flt = nptr; // start of float
	if (*flt == '+') ++flt;
	else if (*flt == '-') sign = -1, ++flt;
	
	if (*flt != '.' && (*flt < '0' || *flt > '9')) {
		// this isn't a float
		*endptr = nptr;
		return 0;
	}
	
	// find the decimal point, if any
	dot = flt;
	while (*dot >= '0' && *dot <= '9') ++dot;
	
	nptr = dot + (*dot == '.');
	// skip digits after the dot
	while (*nptr >= '0' && *nptr <= '9') ++nptr;
	number_end = nptr;
	
	if (*nptr == 'e') {
		++nptr;
		exponent = 1;
		if (*nptr == '+') ++nptr;
		else if (*nptr == '-') ++nptr, exponent = -1;
		exponent *= _strtol_clamped(nptr, &nptr, 10, -10000, 10000); // use _strtol_clamped to prevent problems with -LONG_MIN
	}
	
	// construct the value using the Kahan summation algorithm (https://en.wikipedia.org/wiki/Kahan_summation_algorithm)
	double sum = 0;
	double c = 0;
	for (p = flt; p < number_end; ++p) {
		if (*p == '.') continue;
		int n = *p - '0';
		assert(n >= 0 && n <= 9);
		int pow10 = dot - p;
		pow10 -= pow10 > 0;
		pow10 += exponent;
		_Float f_val = _int_pow10(pow10);
		f_val.fraction >>= 4;
		f_val.exponent += 4;
		f_val.fraction *= n;
		double value = _Float_to_double(f_val);
		if (value == _INFINITY || sum == _INFINITY) {
			sum = _INFINITY;
			break;
		}
		double y = value - c;
		double t = sum + y;
		c = (t - sum) - y;
		sum = t;
	}
	
	if (sum == _INFINITY) errno = ERANGE;
	if (endptr) *endptr = nptr;
	return sum * sign;
}

float strtof(const char *nptr, char **endptr) {
	return strtod(nptr, endptr);
}

long double strtold(const char *nptr, char **endptr) {
	return strtod(nptr, endptr);
}

char *strerror(int errnum) {
	switch (errnum) {
	case ERANGE: return "Range error";
	case EDOM: return "Domain error";
	case EIO: return "I/O error";
	}
	return "Other error";
}

typedef void (*_ExitHandler)(void);
_ExitHandler _exit_handlers[33];
int _n_exit_handlers;

void exit(int status) {
	int i;
	for (i = _n_exit_handlers - 1; i >= 0; --i)
		_exit_handlers[i]();
	_Exit(status);
}

int main();

static char **_envp;
static uint64_t _rand_seed;

int _main(int argc, char **argv) {
	int i;
	_Float p = {1, 0};
	
	_envp = argv + argc + 1; // this is where the environment variables will be
	
	stdin = &_stdin;
	stdout = &_stdout;
	stderr = &_stderr;
	
	/*
	"If rand is called before any calls to srand have been made,
	the same sequence shall be generated as when srand is first
	called with a seed value of 1." C89 § 4.10.2.2 
	*/
	_rand_seed = 1;
	// initialize powers of 10
	_powers_of_10 = _powers_of_10_dat + _NPOW10;
	for (i = 0; i < _NPOW10; ++i) {
		_normalize_float(&p);
		_powers_of_10[i] = p;
		p.exponent += 4;
		p.fraction >>= 4;
		p.fraction *= 10;
	}
	
	p.fraction = 1;
	p.exponent = 0;
	for (i = 0; i > -_NPOW10; --i) {
		_normalize_float(&p);
		_powers_of_10[i] = p;
		p.fraction /= 5;
		p.exponent -= 1;
	}
	
	exit(main(argc, argv));
}


#endif // _STDC_COMMON_H
