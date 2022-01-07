all: out04
out04: in04 ../04/out03
	../04/out03
%.html: %.md ../markdown
	../markdown $<
clean:
	rm -f out* README.html
