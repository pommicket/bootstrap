static char x = -2;

typedef struct {
	int x;
	char y;
	long z;
	long q;
} Structure;


long main(int argc, char **argv) {
	Structure s[] = {3, 5, -88,6,9,12,88,33};
	Structure t = s[0];
	return t.z;
}
