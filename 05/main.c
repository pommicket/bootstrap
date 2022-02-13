long factorial(long x) {
	return x ? x * factorial(x - 1)
		: 1;
}

long fibonacci(long x) {
	return x ?
		x-1 ?
			fibonacci(x-1) + fibonacci(x-2)
		: 1
		: 0;
}

int main(int argc, char **argv) {
	return fibonacci(30);
}

