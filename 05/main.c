#define STRINGIFY2(x) # x
#define STRINGIFY(x) STRINGIFY2(x)
#define JOIN2(x,y) x ##  y
#define JOIN(x,y) JOIN2(x, y)
#define X 22

JOIN(X, X)

STRINGIFY(X)

   #define E 5
#define D E
#define C D
#define B C
#define A B

  int x = E;

main(void) {
}
