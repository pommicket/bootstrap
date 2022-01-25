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
	EEE
} y;
typedef int Bar[EEE];
