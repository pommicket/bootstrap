all: out02
out02: in02 ../02/out01
	../02/out01
out03: out02 in03
	./out02
%.html: %.md ../markdown
	../markdown $<
clean:
	rm -f out* README.html
