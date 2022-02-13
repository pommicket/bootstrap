typedef unsigned long va_list;
#define va_start(list, arg) ((list) = (unsigned long)&arg)
#define va_arg(list, type) (*((type *)(list += ((sizeof(type) + 7) & 0xfffffffffffffff8))))
#define va_end(list)

int sum(int n, ...) {
	va_list args;
	int i;
	int total = 0;
	va_start(args, n);
	for (i = 0; i < n; ++i) {
		total += va_arg(args, int);
	}
	return total;
}

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
	return sum(3, -100, 200, -300);
}

