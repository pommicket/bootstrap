#ifndef _STDLIB_H
#define _STDLIB_H

#include <stdc_common.h>

#define EXIT_FAILURE (-1)
#define EXIT_SUCCESS 0
#define RAND_MAX 2147483647
// @NONSTANDARD: we don't define MB_CUR_MAX or any of the mbtowc functions

typedef struct {
	int quot;
	int rem;
} div_t;

typedef struct {
	long quot;
	long rem;
} ldiv_t;


int execvp(const char *pathname, char *const argv[]) {
	return execve(pathname, argv, _envp);
}


char *getenv(const char *name) {
	int i, j;
	for (i = 0; _envp[i]; ++i) {
		char *key = _envp[i];
		for (j = 0; key[j] != '=' && name[j]; ++j)
			if (name[j] != key[j])
				break;
		if (key[j] == '=' && !name[j])
			return key + (j+1);
	}
	return NULL;
}

double atof(const char *nptr) {
	return strtod(nptr, NULL);
}

int atoi(const char *nptr) {
	return _clamp_long_to_int(strtol(nptr, NULL, 10));
}

long atol(const char *nptr) {
	return strtol(nptr, NULL, 10);
}

int rand(void) {
	// https://en.wikipedia.org/wiki/Linear_congruential_generator
	// we're using musl/newlib's constants
	_rand_seed = 6364136223846793005 * _rand_seed + 1;
	return _rand_seed >> 33;
}

void srand(unsigned seed) {
	_rand_seed = seed;
}

void *calloc(size_t nmemb, size_t size) {
	if (nmemb > 0xffffffffffffffff / size)
		return NULL;
	// NB: our malloc implementation returns zeroed memory
	return malloc(nmemb * size);
}

void *realloc(void *ptr, size_t size) {
	if (!ptr) return malloc(size);
	if (!size) {
		free(ptr);
		return NULL;
	}
#if 0
	// this (better) implementation doesn't seem to be copying stuff to the
	// new mapping properly
	uint64_t *memory = (char *)ptr - 16;
	uint64_t old_size = *memory;
	uint64_t *new_memory = _mremap(memory, old_size, size, MREMAP_MAYMOVE);
	if ((uint64_t)new_memory > 0xffffffffffff0000) return NULL;
	*new_memory = size;
	return (char *)new_memory + 16;
#endif

	uint64_t *memory = (char *)ptr - 16;
	uint64_t old_size = *memory;
	void *new = malloc(size);
	char *new_dat = (char *)new + 16;
	*(uint64_t *)new = size;
	memcpy(new_dat, ptr, old_size);
	free(ptr);
	return new_dat;
}


int atexit(void (*func)(void)) {
	if (_n_exit_handlers >= 32) return -1;
	_exit_handlers[_n_exit_handlers++] = func;
	return 0;
}

int system(const char *string) {
	if (!string) return 1;
	
	int pid = fork();
	if (pid < 0) {
		return -1;
	} else if (pid == 0) {
		// child
		char *argv[] = {
			"/bin/sh",
			"-c",
			0,
			0
		};
		argv[2] = string;
		execve("/bin/sh", argv, _envp);
		// on success, execve does not return.
		_Exit(-1);
	} else {
		// parent
		int status = 0;
		int ret = wait4(pid, &status, 0, NULL);
		if (ret != pid) return -1;
		if (_WIFSIGNALED(status)) return -1;
		return _WEXITSTATUS(status);
	}
	
}

void *bsearch(const void *key, const void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *)) {
	size_t lo = 0;
	size_t hi = nmemb;
	while (lo < hi) {
		size_t mid = (lo + hi) >> 1;
		void *elem = (char *)base + mid * size;
		int cmp = compar(key, elem);
		if (cmp < 0) {
			// key < elem
			hi = mid;
		} else if (cmp) {
			// key > elem
			lo = mid + 1;
		} else {
			return elem;
		}
	}
	return NULL;
}

void qsort(void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *)) {
	// quicksort
	if (nmemb < 2) return;
	
	void *temp = malloc(size);
	void *mid = (char *)base + ((nmemb >> 1) * size); // choose middle element to speed up sorting an already-sorted array
	size_t pivot_index = 0, i;
	for (i = 0; i < nmemb; ++i) {
		void *elem = (char *)base + i * size;
		if (compar(elem, mid) < 0)
			++pivot_index;
	}
	void *pivot = (char *)base + pivot_index * size;
	memcpy(temp, pivot, size);
	memcpy(pivot, mid, size);
	memcpy(mid, temp, size);
	
	char *l, *r = (char *)base + (nmemb-1) * size;
	for (l = base; l < r;) {
		if (compar(l, pivot) > 0) {
			// swap l and r
			memcpy(temp, l, size);
			memcpy(l, r, size);
			memcpy(r, temp, size);
			r -= size;
		} else {
			// l is already in the right place
			l += size;
		}
	}
	
	qsort(base, pivot_index, size, compar);
	qsort((char *)pivot + size, nmemb - 1 - pivot_index, size, compar);
	
	free(temp);
}

int abs(int x) {
	return x >= 0 ? x : -x;
}

long labs(long x) {
	return x >= 0 ? x : -x;
}

div_t div(int numer, int denom) {
	div_t d;
	d.quot = numer / denom;
	d.rem = numer % denom;
	return d;
}

ldiv_t ldiv(long numer, long denom) {
	ldiv_t d;
	d.quot = numer / denom;
	d.rem = numer % denom;
	return d;
}

#endif // _STDLIB_H
