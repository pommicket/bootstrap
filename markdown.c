/*
a little program to convert markdown to html, for READMEs
I was using markdown.pl but that has some annoying problems
This doesn't support all of markdown; I'll add more as I need it.
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* output text with *s for italics and stuff */
static void output_md_text(FILE *out, int *flags, int line_number, const char *text) {
	enum {
		FLAG_I = 0x01, /* italics */
		FLAG_B = 0x02,
		FLAG_CODE = 0x04
	};
	const char *p;

	for (p = text; *p; ++p) {
		if ((*flags & FLAG_CODE) && *p != '`') {
			switch (*p) {
			case '<': fprintf(out, "&lt;"); break;
			case '>': fprintf(out, "&gt;"); break;
			case '&': fprintf(out, "&amp;"); break;
			default: putc(*p, out); break;
			}
			continue;
		}
		switch (*p) {
		case '\\':
			++p;
			if (*p == '\0') {
				fprintf(stderr, "line %d: Unterminated \\.\n", line_number);
				exit(-1);
			}
			fprintf(out, "%c", *p);
			break;
		case '*':
			if (p[1] == '*') {
				/* bold */
				if (*flags & FLAG_B) {
					fprintf(out, "</b>");
					*flags &= ~FLAG_B;
				} else {
					fprintf(out, "<b>");
					*flags |= FLAG_B;
				}
				++p;
			} else {
				/* italics */
				if (*flags & FLAG_I) {
					fprintf(out, "</i>");
					*flags &= ~FLAG_I;
				} else {
					fprintf(out, "<i>");
					*flags |= FLAG_I;
				}
			}
			break;
		case '`':
			/* code */
			if (*flags & FLAG_CODE) {
				fprintf(out, "</code>");
				*flags &= ~FLAG_CODE;
			} else {
				fprintf(out, "<code>");
				*flags |= FLAG_CODE;
			}
			break;
		case '[': {
			/* link */
			char url2[256] = {0};
			const char *label, *url, *label_end, *url_end;
			char *dot;
			int n_label, n_url;

			label = p+1;
			label_end = strchr(label, ']');
			if (!label_end) {
				fprintf(stderr, "line %d: Unterminated link.\n", line_number);
				exit(-1);
			}
			if (label_end[1] != '(') {
				fprintf(stderr, "line %d: Bad link syntax.\n", line_number);
				exit(-1);
			}
			url = label_end + 2;
			url_end = strchr(url, ')');
			if (!url_end) {
				fprintf(stderr, "line %d: Unterminated URL.\n", line_number);
				exit(-1);
			}

			n_label = (int)(label_end - label);
			n_url  = (int)(url_end  - url);
			if (n_url > sizeof url2-8)
				n_url = sizeof url2-8;
			sprintf(url2, "%.*s", n_url, url);
			dot = strrchr(url2, '.');
			if (dot && strcmp(dot, ".md") == 0) {
				/* replace links to md files with links to html files */
				strcpy(dot, ".html");
			}
			fprintf(out, "<a href=\"%s\">%.*s</a>",
				url2, n_label, label);
			p = url_end;
		} break;
		case '-':
			if (p[1] == '-') {
				/* em dash */
				fprintf(out, "—");
				++p;
			} else {
				goto default_case;
			}
			break;
		default:
		default_case:
			putc(*p, out);
			break;
		}
	}
}

int main(int argc, char **argv) {
	FILE *in, *out;
	char line[1024] = {0};
	char title[256] = {0};
	int flags = 0, txtflags = 0;
	int line_number = 0;
	enum {
		FLAG_UL = 1
	};

	if (argc < 2) {
		fprintf(stderr, "Please provide an input file.\n");
		return -1;
	}

	{
		const char *in_filename = argv[1];
		char out_filename[256] = {0};
		char *dot;
		strncpy(out_filename, argv[1], 200);
		dot = strrchr(out_filename, '.');
		if (!dot || strcmp(dot, ".md") != 0) {
			fprintf(stderr, "Input filename does not end in .md\n");
			return -1;
		}
		*dot = '\0';
		strcpy(title, out_filename);
		strcpy(dot, ".html");


		in = fopen(in_filename, "rb");
		out = fopen(out_filename, "wb");
	}

	if (!in) {
		perror("Couldn't open input file");
		return -1;
	}
	if (!out) {
		perror("Couldn't open output file");
		return -1;
	}

	fprintf(out,
		"<!DOCTYPE html>\n"
		"<html lang=\"en\">\n"
		"<head>\n"
		"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
		"<meta charset=\"utf-8\">\n"
		"<style>\n"
		"body { font-family: serif; }\n"
		"</style>\n"
		"<title>%s</title>\n"
		"</head>\n"
		"<body>\n"
		"<p>\n", title
	);
	while (fgets(line, sizeof line, in)) {
		++line_number;
		line[strcspn(line, "\r\n")] = '\0';

		if (line[0] == '#') {
			/* heading */
			int n = 1;
			while (line[n] == '#') ++n;
			fprintf(out, "</p><h%d>", n);
			output_md_text(out, &txtflags, line_number, line + n);
			fprintf(out, "</h%d><p>\n", n);
		} else if (line[0] == '\0') {
			if (flags & FLAG_UL) {
				fprintf(out, "</li></ul>\n");
				flags &= ~FLAG_UL;
			}
			fprintf(out, "</p>\n<p>\n");
		} else if (strncmp(line, "- ", 2) == 0) {
			/* bullet */
			if (flags & FLAG_UL) {
				fprintf(out, "</li><li>");
			} else {
				fprintf(out, "<ul><li>");
				flags |= FLAG_UL;
			}
			output_md_text(out, &txtflags, line_number, line + 2);
			fprintf(out, "\n");
		} else if (strncmp(line, "```", 3) == 0) {
			fprintf(out, "<pre><code>\n");
			
			while (fgets(line, sizeof line, in)) {
				char *p;
				++line_number;
				if (strncmp(line, "```", 3) == 0)
					break;
				for (p = line; *p; ++p) {
					switch (*p) {
					case '<': fprintf(out, "&lt;"); break;
					case '>': fprintf(out, "&gt;"); break;
					case '&': fprintf(out, "&amp;"); break;
					default: fputc(*p, out); break;
					}
				}
			}

			fprintf(out, "</code></pre>\n");
		} else {
			output_md_text(out, &txtflags, line_number, line);
			fprintf(out, "\n");
		}



	}
	fprintf(out, "</p>\n</body>\n</html>\n");
	return 0;
}
