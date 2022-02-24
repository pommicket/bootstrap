#include "stdio_impl.h"

#undef feof

int feof(FILE *f)
{
	return !!(f->flags & F_EOF);
}

int feof_unlocked(FILE *f)
{
	return !!(f->flags & F_EOF);
}
