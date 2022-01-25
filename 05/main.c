/*typedef struct {
	int i[41];
	long double d;
} (*x)(void);
*/
typedef int Foo[(char)((unsigned char)0xff + (unsigned char)0xf02)];
typedef enum {
	HELLO,
	THERE,
	TEST = 1-3,
	EEE = TEST+4,
	ASDFASDF,
	FFF,
	HELLO2
} y;
typedef int Bar[FFF];
