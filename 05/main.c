/*typedef struct {
	int i[41];
	long double d;
} (*x)(void);

/* typedef enum X { */
/* 	R,S,T */
/*  } *Foo[sizeof(unsigned long)]; */
/* typedef int A[T]; */

typedef struct A {
	int x, y;
	long double c;
	unsigned long d;
	char e[3];
	long f;
} A;

typedef union B{
	int x;
	struct {
		int y;
		struct {long z; } c;
	} c;
}B;

typedef int x[sizeof(A)];
typedef int y[sizeof(struct B)];
