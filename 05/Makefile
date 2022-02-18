TCCDIR=tcc-0.9.27
TCC=$(TCCDIR)/tcc
all: out04 a.out test.out README.html
in04: *.b ../04a/out04
	../04a/out04 main.b in04
out04: in04 ../04/out03
	../04/out03 in04 out04
%.html: %.md ../markdown
	../markdown $<
%.out: %.c *.h out04
	./out04 $< $@
a.out: main.c *.h out04
	./out04
test.out: $(TCC) test.s.o test.c.o
	$(TCC) -static -nostdlib test.s.o test.c.o -o test.out
test.s.o: $(TCC) test.s
	$(TCC) -static -nostdlib -c test.s -o test.s.o
test.c.o: $(TCC) test.c
	$(TCC) -static -nostdlib -c test.c -o test.c.o
$(TCC): $(TCCDIR)/*.c $(TCCDIR)/*.h out04
	cd $(TCCDIR) && ../out04 tcc.c tcc
clean:
	rm -f out* README.html *.out *.o $(TCC)
