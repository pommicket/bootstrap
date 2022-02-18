#ifndef _SETJMP_H
#define _SETJMP_H

#include <stdc_common.h>

typedef long jmp_buf[3];

// @NONSTANDARD: we don't actually support setjmp

int setjmp(jmp_buf env) {
	return 0;
}

void __longjmp(jmp_buf env, int val, const char *filename, int line) {
	fprintf(stderr, "Error: Tried to longjmp from %s:%d with value %d\n", filename, line, val);
	_Exit(-1);
}

#define longjmp(env, val) __longjmp(env, val, __FILE__, __LINE__)

#endif
