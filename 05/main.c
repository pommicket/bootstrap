#define f(x) x x

f(2
3)

#define STRINGIFY(x) #x
#define MY_FILE STRINGIFY(some_file.c)
#define LINE_NUMBER 1982

#line LINE_NUMBER MY_FILE

#pragma
