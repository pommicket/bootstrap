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
/*  */
/* static unsigned int x={55}; */
/* static char *s = "hello"; */
/* static char *t = "goodbye"; */
/* static char u[8] = "hellothe"; */
/* static char v[100] = "re my"; */
/* static char w[] = "friendly"; */
/* static char x_[] = "hi"; */
/* typedef int A[sizeof x_ + sizeof u]; */
/*  */
/* static int a[5] = {1,2,3}; */
/* static char b[6][7] = {{'a'},{'b'},{'c'},{'d'},{'e'}}; */
/* static char __b[][7] = {{'a'},"hello",'r'}; */
/* static int _u = sizeof __b; */

/* struct { */
/* 	int a; */
/* 	long b; */
/* } x1[] = {0x1234567890, 1ul<<60|1ul<<3, 77}; */
/* int y1 = 0x12345678; */
typedef int R[sizeof *(int*)"hello"];

/* struct { */
/* 	int x[2], y; */
/* } test = {3, 5}; */
/* unsigned marker = 0xdeadbeef; */
