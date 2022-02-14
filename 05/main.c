#include <stdio.h>

int main(int argc, char **argv) {
	char buf[200] = {0};
	snprintf(buf, sizeof buf, "Hello, %d %.2f %g %s %p\n", 187, 77.3, 349e12, "Wow!", "yea");
/* 	write(1, buf, sizeof buf); */
	printf("%s\n",buf);
	return 0;
}

