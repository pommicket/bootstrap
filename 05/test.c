// calling assembly functions from C is not working for some reason.
extern unsigned long __syscall(int, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long);
int main(unsigned long (*_syscall)(int, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long)) {
	__syscall(1, 1, (unsigned long)"Hello, world!\n", 14, 0, 0, 0);
	return 42;
}
