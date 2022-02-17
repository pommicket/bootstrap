#define _STDLIB_DEBUG
#include <math.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>

int compar(const void *a, const void *b) {
	int i = *(int *)a;
	int j = *(int *)b;
	if (i < j) return -1;
	if (i > j) return 1;
	return 0;
}

int main(int argc, char **argv) {
	char buf[36];
	strcpy(buf, "Hello there there!");
/* 	buf[36]='b'; */
	printf("%s\n",strstr(buf," ther"));
	
         static char str[] = "?a???b,,,#c";
         char *t;
        
         printf("%s\n", strtok(str, "?"));      /* t  points to the token "a" */
         printf("%s\n", strtok(NULL, ",")); 
         printf("%s\n", strtok(NULL, "#,")); 
         printf("%s\n", strtok(NULL, "?")); 
         

	return 0;
}

