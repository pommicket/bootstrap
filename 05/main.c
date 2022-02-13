long factorial(long x) {
	if (x == 0) {
		return 1;
	} else {
		return x * factorial(x-1);
	}
}

long fibonacci(long x) {
	return x > 0 ?
		x > 1 ?
			fibonacci(x-1) + fibonacci(x-2)
		: 1
		: 0;
}

long gcd(long a, long b) {
	while (a != 0) {
		long temp = a;
		a = b % a;
		b = temp;
	}
	return b;
}

int f() {
	lb: goto lb;
}

int main(int argc, char **argv) {	
	return fibonacci(20);
}

