#ifndef _GETOPT_H
#define _GETOPT_H

#ifdef __cplusplus
extern "C" {
#endif

int getopt(int, char * const [], const char *);
extern char *optarg;
extern int optind, opterr, optopt;

#ifdef _GNU_SOURCE
struct option
{
	const char *name;
	int has_arg;
	int *flag;
	int val;
};

int getopt_long(int, char *const *, const char *, const struct option *, int *);
int getopt_long_only(int, char *const *, const char *, const struct option *, int *);

#define no_argument        0
#define required_argument  1
#define optional_argument  2
#endif

#ifdef __cplusplus
}
#endif

#endif
