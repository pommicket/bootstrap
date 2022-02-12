static char x = -2;

typedef struct {
	int x;
	char y;
	int z;
} Structure;


long main(int argc, char **argv) {
Structure s[] = {3, 5, -88,6,9,12};
	Structure *ps = s;
	int *p = &ps->z;
	return *p;
}
