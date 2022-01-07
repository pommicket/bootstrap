all: out04 out04a README.html
out04: in04 ../04/out03
	../04/out03
out04a: in04a out04
	./out04
%.html: %.md ../markdown
	../markdown $<
clean:
	rm -f out* README.html
