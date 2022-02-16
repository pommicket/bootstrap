#define _STDLIB_DEBUG
#include <math.h>
#include <stdio.h>
#include <signal.h>

int main(int argc, char **argv) {
	raise(SIGKILL);
	return 0;
}

