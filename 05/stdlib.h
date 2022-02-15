#ifndef _STDLIB_H
#define _STDLIB_H

#include <stdc_common.h>

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

#endif // _STDLIB_H
