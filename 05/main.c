#define _STDLIB_DEBUG
#include <stdio.h>
#include <string.h>

int main(void) {
	char *s = "1.35984534e135-e12hello";
	char *end;
	_Float f = _powers_of_10[-307];
	printf("%.15g\n",strtod(s, &end));
	printf("%s\n",end);
	return 0;
}

