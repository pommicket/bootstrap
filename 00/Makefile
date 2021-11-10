all: README.html out00
out00: in00
	./hexcompile
%.html: %.md ../markdown
	../markdown $<
clean:
	rm -f out00 README.html
