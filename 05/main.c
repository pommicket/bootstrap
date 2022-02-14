#include <stdio.h>

int main(int argc, char **argv) {
	char buf[200] = {0};
	sprintf(buf, "Hello, %d %.2f %g %s %p\n", 187, 77.3, 349e12, "Wow!", "yea");
 //	snprintf(buf, 200, "Hello\n");  //<- NOT WORKING
	write(1, buf, sizeof buf);
	return *buf;
}

