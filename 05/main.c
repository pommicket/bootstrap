#define _STDLIB_DEBUG
#include <math.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>


int compar(const void *a, const void *b) {
	int i = *(int *)a;
	int j = *(int *)b;
	if (i < j) return -1;
	if (i > j) return 1;
	return 0;
}

int main(int argc, char **argv) {
	ldiv_t l = ldiv(1000000000007, 5937448);
	printf("%ld %ld\n",l.quot,l.rem);
	int nums[10] = {8,34,1086,3872,-123,5873,3843,1762,INT_MAX,INT_MIN};
	int i;
	for (i = 0; i < 10; ++i) nums[i] = abs(nums[i]);
	qsort(nums, 10, sizeof(int), compar);
	for (i = 0; i < 10; ++i) printf("%d ", nums[i]);
	printf("\n");
	int search = 34;
	int *p = bsearch(&search, nums, 10, sizeof(int), compar);
	if (p)
		printf("Found %d\n",*p);
	else
		printf("No match\n");
	return 0;
}

