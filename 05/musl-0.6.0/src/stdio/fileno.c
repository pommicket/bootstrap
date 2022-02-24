#include "stdio_impl.h"

int fileno(FILE *f)
{
	return f->fd;
}

int fileno_unlocked(FILE *f)
{
	return f->fd;
}
