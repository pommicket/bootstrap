#define _STDLIB_DEBUG
#include <math.h>
#include <stdio.h>
#include <signal.h>

void test_signal_handler(int x) {
	printf("interompu\n");
	_Exit(0);
}

int main(int argc, char **argv) {
	signal(SIGINT, test_signal_handler);
	while (1){}
	return 0;
}

