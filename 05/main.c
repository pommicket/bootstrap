#include <stdio.h>
#include <string.h>

int main(void) {
	char nam[L_tmpnam];
	printf("%s\n", tmpnam(nam));
	
	return 0;
}

