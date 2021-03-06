#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

const char *inet_ntop(int af, const void *a0, char *s, socklen_t l)
{
	const unsigned char *a = a0;
	int i, j, max, best;
	char buf[100];

	switch (af) {
	case AF_INET:
		if (snprintf(s, l, "%d.%d.%d.%d", a[0],a[1],a[2],a[3]) < l)
			return s;
		break;
	case AF_INET6:
		memset(buf, 'x', sizeof buf);
		buf[sizeof buf-1]=0;
		snprintf(buf, sizeof buf, 
			"%.0x%x:%.0x%x:%.0x%x:%.0x%x:%.0x%x:%.0x%x:%.0x%x:%.0x%x",
			a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],
			a[8],a[9],a[10],a[11],a[12],a[13],a[14],a[15]);
		/* Replace longest /(^0|:)[:0]{2,}/ with "::" */
		for (i=best=0, max=2; buf[i]; i++) {
			if (i && buf[i] != ':') continue;
			j = strspn(buf+i, ":0");
			if (j>max) best=i, max=j;
		}
		if (max>2) {
			buf[best] = buf[best+1] = ':';
			strcpy(buf+best+2, buf+best+max);
		}
		if (strlen(buf) < l) {
			strcpy(s, buf);
			return s;
		}
		break;
	default:
		errno = EAFNOSUPPORT;
		return 0;
	}
	errno = ENOSPC;
	return 0;
}
