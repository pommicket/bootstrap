#define _STDLIB_DEBUG
#include <stdio.h>
#include <string.h>

int main(void) {
	char s[] = "   -0XAh.\n";
	char *end;
	errno = 0;
	printf("%ld\n", strtol(s, &end, 0));
	printf("%d:%s",errno,end);
	return 0;
}

