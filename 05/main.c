/* #define _STDLIB_DEBUG */
/* #include <math.h> */
#include <stdio.h>
/* #include <signal.h> */
/* #include <stdlib.h> */
/* #include <string.h> */
/* #include <time.h> */
/* #include <float.h> */
/* #include <setjmp.h> */
/*  */

int main(int argc, char **argv) {
	int *p = 0x100;
	p += 1;
	printf("%p\n",p);
	return 0;
}

