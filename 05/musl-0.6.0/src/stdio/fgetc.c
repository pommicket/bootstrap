#include "stdio_impl.h"

int fgetc(FILE *f)
{
	int c;
	FLOCK(f);
	c = f->rpos < f->rstop ? *f->rpos++ : __uflow(f);
	FUNLOCK(f);
	return c;
}

int fgetc_unlocked(FILE *f)
{
	int c;
	FLOCK(f);
	c = f->rpos < f->rstop ? *f->rpos++ : __uflow(f);
	FUNLOCK(f);
	return c;
}
