#define _STDLIB_DEBUG
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stddef.h>
#include <ctype.h>
#include <locale.h>

int main(int argc, char **argv) {
	setlocale(LC_ALL, "C");
	struct lconv *c = localeconv();
	printf("%s\n",c->negative_sign);
	return 0;
}

