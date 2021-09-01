all: out01 README.html
out01: in01 out00
	./out00
out00: in00
	../00/hexcompile
%.html: %.md ../markdown
	../markdown $<
