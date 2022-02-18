extern unsigned long __syscall(int, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long);
int main(void) {
	__syscall(1, 1, (unsigned long)"Hello, world!\n", 14, 0, 0, 0);
	return 42;
}
