all: README.html out00
%.html: %.md
	markdown $< > $@
out00: in00
	./hexcompile
