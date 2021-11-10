all: markdown README.html
	$(MAKE) -C 00
	$(MAKE) -C 01
	$(MAKE) -C 02
markdown: markdown.c
	$(CC) -O2 -o markdown -Wall -Wconversion -Wshadow -std=c89 markdown.c
README.html: markdown README.md
	./markdown README.md
