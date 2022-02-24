#include "stdio_impl.h"

#undef ferror

int ferror(FILE *f)
{
	return !!(f->flags & F_ERR);
}

int ferror_unlocked(FILE *f)
{
	return !!(f->flags & F_ERR);
}
