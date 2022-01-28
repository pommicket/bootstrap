/*typedef struct {
	int i[41];
	long double d;
} (*x)(void);

/* typedef enum X { */
/* 	R,S,T */
/*  } *Foo[sizeof(unsigned long)]; */
/* typedef int A[T]; */
/*  */
/* typedef struct A { */
/* 	int x, y; */
/* 	long double c; */
/* 	unsigned long d; */
/* 	char e[3]; */
/* 	long f; */
/* } A; */
/*  */
/* typedef union B{ */
/* 	int x; */
/* 	struct { */
/* 		int y; */
/* 		struct {long z; } c; */
/* 	} c; */
/* }B; */
/*  */
/* typedef int x[sizeof(A)+sizeof"hello"]; */
/* typedef int y[sizeof(struct B)]; */

static unsigned int x;
static unsigned int y;
static unsigned int z[1000];
static unsigned int w;

/*
NOTE: THIS MUST WORK
int x[] = {1,2,3}
sizeof x
*/
