#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
	printf("%p\n", malloc(1024*16));
	int *list = malloc(1024*4);
	printf("%p \n",list);
	list[1023] = 77;
	list = realloc(list, 1024*64);
	printf("%p \n",list);
	printf("%d\n",list[1023]);
	free(list);
	return 0;
}

