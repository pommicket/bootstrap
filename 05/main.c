#define F(x) x x

F(2
3)

#define STRINGIFY(x) #x
#define LINE_NUMBER 1982
#define INC_FILE STRINGIFY(macro_test.c)

#include INC_FILE /* include macro test */

a
#ifndef INC_FILEd

xglue(LINE_,NUMBER)
#else
Hello
#endif
b

#pragma
