static char x = -2;
long main(int argc, char **argv) {
	int y[] = {38, 55, -22};
	int *z = (y+2)[-1];
	return *z;
}
