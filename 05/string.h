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
	for (; ; ++p, ++q) {
		if (*p > *q)
			return 1;
		if (*p < *q)
			return -1;
		if (!*p) break;
	}
	return 0;
}

int strcoll(const char *s1, const char *s2) {
	// we only support the C locale
	return strcmp(s1, s2);
}

int strncmp(const char *s1, const char *s2, size_t n) {
	char *p = s1, *q = s2;
	size_t i;
	for (i = 0; i < n; ++i, ++p, ++q) {
		if (*p > *q)
			return 1;
		if (*p < *q)
			return -1;
		if (!*p) break;
	}
	return 0;
}

size_t strxfrm(char *s1, const char *s2, size_t n) {
	// we only support the C locale
	size_t l = strlen(s2);
	if (l >= n) return l;
	strcpy(s1, s2);
	return l;
}

void *memchr(const void *s, int c, size_t n) {
	char *p = s, *end = p + n;
	while (p < end) {
		if ((unsigned char)*p == c)
			return p;
		++p;
	}
	return NULL;
}

char *strchr(const char *s, int c) {
	return memchr(s, c, strlen(s)+1);
}


size_t strcspn(const char *s1, const char *s2) {
	const char *p, *q;
	for (p = s1; *p; ++p) {
		for (q = s2; *q; ++q) {
			if (*p == *q)
				goto ret;
		}
	}
	ret:
	return p - s1;
}

char *strpbrk(const char *s1, const char *s2) {
	const char *p, *q;
	for (p = s1; *p; ++p) {
		for (q = s2; *q; ++q) {
			if (*p == *q)
				return p;
		}
	}
	return NULL;
}

char *strrchr(const char *s, int c) {
	char *p;
	for (p = s + strlen(s); p >= s; --p) {
		if (*p == c)
			return p;
	}
	return NULL;
}

size_t strspn(const char *s1, const char *s2) {
	const char *p, *q;
	for (p = s1; *p; ++p) {
		for (q = s2; *q; ++q) {
			if (*p == *q) break;
		}
		if (!*q) break;
	}
	return p - s1;
}

char *strstr(const char *s1, const char *s2) {
	char *p;
	size_t l = strlen(s2);
	for (p = s1; *p; ++p) {
		if (memcmp(p, s2, l) == 0)
			return p;
	}
	return NULL;
}

char *_strtok_str;
char *strtok(char *s1, const char *s2) {
	if (s1) _strtok_str = s1;
	if (!_strtok_str) return NULL;
	char *p = _strtok_str + strspn(_strtok_str, s2);
	if (!*p) {
		_strtok_str = NULL;
		return NULL;
	}
	char *q = strpbrk(p, s2);
	if (q) {
		*q = 0;
		_strtok_str = q + 1;
	} else {
		_strtok_str = NULL;
	}
	return p;
}

#endif // _STRING_H
