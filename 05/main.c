/*typedef struct {
	int i[41];
	long double d;
} (*x)(void);
*/
typedef long int unsigned Foo[sizeof"hello"+sizeof(double[sizeof(int) * sizeof 3])];
typedef int (*x)(Foo);
/* */
