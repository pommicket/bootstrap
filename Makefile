all: markdown README.html
	$(MAKE) -C 00
	$(MAKE) -C 01
	$(MAKE) -C 02
	$(MAKE) -C 03
	$(MAKE) -C 04
	$(MAKE) -C 04a
clean:
	$(MAKE) -C 00 clean
	$(MAKE) -C 01 clean
	$(MAKE) -C 02 clean
	$(MAKE) -C 03 clean
	$(MAKE) -C 04 clean
	$(MAKE) -C 04a clean
	rm -f markdown
	rm -f README.html
markdown: markdown.c
	$(CC) -O2 -o markdown -Wall -Wconversion -Wshadow -std=c89 markdown.c
README.html: markdown README.md
	./markdown README.md
