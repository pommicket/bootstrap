#ifndef _STDDEF_H
#define _STDDEF_H

#include <stdc_common.h>
#define offsetof(struct, member) ((size_t)(&((struct *)NULL)->member))
// @NONSTANDARD: we don't have wchar_t

#endif // _STDDEF_H
