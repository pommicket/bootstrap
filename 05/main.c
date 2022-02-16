#define _STDLIB_DEBUG
#include <math.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>

int compar(const void *a, const void *b) {
	int i = *(int *)a;
	int j = *(int *)b;
	if (i < j) return -1;
	if (i > j) return 1;
	return 0;
}

int main(int argc, char **argv) {
	char buf[36];
	memset(buf, 'a', sizeof buf);
	strncpy(buf, "hello, world!\n",36);
	printf("%d\n",strcmp(buf, "hello, world!\n"));
	return 0;
}

