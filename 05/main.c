#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
	printf("%s\n",remove("test_file")?"failure":"success");
	return 0;
}

