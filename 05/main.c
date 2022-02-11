/*
; @NONSTANDARD:
;  the following does not work:
;     typedef struct T Type;
;     struct T{
;            int m;
;     };
;     ...
;     Type *x = ...;
;     x->m;   *trying to access member of incomplete struct
This needs to be fixed because otherwise you can't do:
struct A { struct B *blah; }
struct B { struct A *blah; }
*/

int main(int argc, char **argv) {
	return (float)(long)"hello";
}
