#define _STDLIB_DEBUG
#include <math.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <float.h>
#include <setjmp.h>

int main(int argc, char **argv) {
	jmp_buf test;
	setjmp(test);
	longjmp(test, 5);
	return 0;
}

