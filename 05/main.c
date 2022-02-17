#define _STDLIB_DEBUG
#include <math.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <float.h>

int main(int argc, char **argv) {
	srand(time(NULL));
	printf("%d\n",rand());
	return 0;
}

