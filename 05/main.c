#define _STDLIB_DEBUG
#include <stdio.h>
#include <string.h>

int main(void) {
         int count; float quant; char units[21], item[21];
         while (!feof(stdin) && !ferror(stdin)) {
                  count = fscanf(stdin, "%f%20s of %20s",
                           &quant, units, item);
                  fscanf(stdin,"%*[^\n]");
                  printf("%d %g %s %s\n", count, quant, units, item);
         }
	return 0;
}

