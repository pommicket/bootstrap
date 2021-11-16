all: out03
out03: in03 ../03/out02
	../03/out02
%.html: %.md ../markdown
	../markdown $<
clean:
	rm -f out* README.html
