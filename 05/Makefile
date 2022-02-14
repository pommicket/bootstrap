all: out04 a.out
in04: *.b ../04a/out04
	../04a/out04 main.b in04
out04: in04 ../04/out03
	../04/out03 in04 out04
%.html: %.md ../markdown
	../markdown $<
%.out: %.c
	./out04 $< $@
a.out: main.c
	./out04
clean:
	rm -f out* README.html *.out
