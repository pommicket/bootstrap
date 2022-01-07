all: out03 guessing_game.out out04b README.html
out03: in03 ../03/out02
	../03/out02
%.html: %.md ../markdown
	../markdown $<
out04b: in04b out03
	./out03
%.out: % out03
	./out03 $< $@
clean:
	rm -f out* README.html *.out
