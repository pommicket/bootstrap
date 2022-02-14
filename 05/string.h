#ifndef _STRING_H
#define _STRING_H

#include <stdc_common.h>

void *memset(void *s, int c, size_t n) {
	char *p = s, *end = p + n;
	while (p < end)
		*p++ = c;
	return s;
}


#endif // _STRING_H
