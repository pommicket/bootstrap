#include "stdio_impl.h"

int fputc(int c, FILE *f)
{
	FLOCK(f);
	if (c != f->lbf && f->wpos + 1 < f->wend) *f->wpos++ = c;
	else c = __overflow(f, c);
	FUNLOCK(f);
	return c;
}

int fputc_unlocked(int c, FILE *f)
{
	FLOCK(f);
	if (c != f->lbf && f->wpos + 1 < f->wend) *f->wpos++ = c;
	else c = __overflow(f, c);
	FUNLOCK(f);
	return c;
}
