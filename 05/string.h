#ifndef _STRING_H
#define _STRING_H

#include <stdc_common.h>


void *memmove(void *s1, const void *s2, size_t n) {
	if (s1 < s2) return memcpy(s1, s2, n); // our memcpy does a forwards copy
	// backwards copy
	char *p = (char*)s1 + n, *q = (char*)s2 + n;
	while (p > s1)
		*--p = *--q;
	return s1;
}

char *strcpy(char *s1, const char *s2) {
	char *p = s1 - 1, *q = s2 - 1;
	while ((*++p = *++q));
	return s1;
}

char *strncpy(char *s1, const char *s2, size_t n) {
	char *p = s1 - 1, *q = s2 - 1;
	size_t i;
	for (i = 0; i < n; ++i)
		if (!(*++p = *++q))
			break;
	for (; i < n; ++i)
		*++p = 0;
	return s1;
}

char *strcat(char *s1, const char *s2) {
	return strcpy(s1 + strlen(s1), s2);
}

char *strncat(char *s1, const char *s2, size_t n) {
	// oddly, not equivalent to strncpy(s1 + strlen(s1), s2, n)
	char *p = s1 + strlen(s1) - 1, *q = s2 - 1;
	size_t i;
	for (i = 0; i < n; ++i)
		if (!(*++p = *++q))
			break;
	*++p = 0;
	return s1;
}

int memcmp(const void *s1, const void *s2, size_t n) {
	char *p = s1, *q = s2;
	size_t i;
	for (i = 0; i < n; ++i, ++p, ++q) {
		if (*p > *q)
			return 1;
		if (*p < *q)
			return -1;
	}
	return 0;
}

int strcmp(const char *s1, const char *s2) {
	char *p = s1, *q = s2;
	for (; *p && *q; ++p, ++q) {
		if (*p > *q)
			return 1;
		if (*p < *q)
			return -1;
	}
	if (*p > *q)
		return 1;
	if (*p < *q)
		return -1;
	return 0;
}

#endif // _STRING_H
