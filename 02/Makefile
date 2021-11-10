all: out01 out02 README.html
out01: in01
	../01/out00
out02: out01 in02
	./out01
%.html: %.md ../markdown
	../markdown $<
clean:
	rm -f out01 out02 README.html
