#ifndef _CTYPE_H
#define _CTYPE_H

#include <stdc_common.h>

int islower(int c) {
	return c >= 'a' && c <= 'z';
}

int isupper(int c) {
	return c >= 'A' && c <= 'Z';
}

int isalpha(int c) {
	return isupper(c) || islower(c);
}

int isalnum(int c) {
	return isalpha(c) || isdigit(c);
}

int isprint(int c) {
	if (isalnum(c)) return 1;
	switch (c) {
	case '!': return 1;
	case '@': return 1;
	case '#': return 1;
	case '$': return 1;
	case '%': return 1;
	case '^': return 1;
	case '&': return 1;
	case '*': return 1;
	case '(': return 1;
	case ')': return 1;
	case '-': return 1;
	case '=': return 1;
	case '_': return 1;
	case '+': return 1;
	case '`': return 1;
	case '~': return 1;
	case '[': return 1;
	case '{': return 1;
	case ']': return 1;
	case '}': return 1;
	case '\\': return 1;
	case '|': return 1;
	case ';': return 1;
	case ':': return 1;
	case '\'': return 1;
	case '"': return 1;
	case ',': return 1;
	case '<': return 1;
	case '.': return 1;
	case '>': return 1;
	case '/': return 1;
	case '?': return 1;
	}
	return 0;
}

int iscntrl(int c) {
	return !isprint(c);
}

int isgraph(int c) {
	return isprint(c) && c != ' ';
}

int ispunct(int c) {
	return isprint(c) && c != ' ' && !isalnum(c);
}

int isxdigit(int c) {
	if (isdigit(c)) return 1;
	if (c >= 'a' && c <= 'f') return 1;
	if (c >= 'A' && c <= 'F') return 1;
	return 0;
}

int tolower(int c) {
	if (c >= 'A' && c <= 'Z')
		return c - 'A' + 'a';
	return c;
}

int toupper(int c) {
	if (c >= 'a' && c <= 'z')
		return c - 'a' + 'A';
	return c;
}

#endif // _CTYPE_H
