#define STRINGIFY2(x) #x
#define STRINGIFY(x) STRINGIFY2(x)
#define X 22
STRINGIFY(X)


#define E 5
#define D E
#define C D
#define B C
#define A B

int x = E;

main(void) {
}
