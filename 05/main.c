/*typedef struct {
	int i[41];
	long double d;
} (*x)(void);
*/
typedef long int unsigned (*Foo(int *,int,int,unsigned,void (*)(int)))(int x);
