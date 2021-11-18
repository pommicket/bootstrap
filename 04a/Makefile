all: out03 out04a README.html
out03: in03 ../03/out02
	../03/out02
out04a: out03 in04a
	./out03 in04a out04a
%.html: %.md ../markdown
	../markdown $<
clean:
	rm -f out* README.html
