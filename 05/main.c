typedef struct {
	long a;
	long aah[810];
	long b;
} Structure;

Structure mkstruct(int x, int y) {
	Structure s;
	s.a = x;
	s.b = y;
	return s;
}

Structure mkstruct1(int x) {
	return mkstruct(x, x*2);
}

Structure mkstruct_a() {
	return mkstruct1(1033.3);
}


long main(int argc, char **argv) {
	Structure t;
	t = mkstruct_a();
	return t.b;
}

