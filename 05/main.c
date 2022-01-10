#define z sz
z

#define STRINGIFY2(x) # x
#define STRINGIFY(x) STRINGIFY2(x)
#define JOIN2(x,y) x ##  y
#define JOIN(x,y) JOIN2(x, y)
#define X 22

JOIN(X, X)

STRINGIFY(X)

#line 6

#line 7 "some_file.c"
#pragma whatever

main(void) {
}
