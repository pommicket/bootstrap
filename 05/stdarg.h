#ifndef _STDARG_H
#define _STDARG_H

typedef unsigned long va_list;

#define va_start(list, arg) ((list) = (unsigned long)&arg)
#define va_arg(list, type) (*((type *)(list += ((sizeof(type) + 7) & 0xfffffffffffffff8))))
#define va_end(list)

#endif // _STDARG_H
