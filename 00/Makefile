all: README.html out00
out00: in00
	./hexcompile
%.html: %.md ../markdown
	../markdown $<
