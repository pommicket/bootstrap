#ifndef _UTMPX_H
#define _UTMPX_H

#ifdef __cplusplus
extern "C" {
#endif

#define __NEED_pid_t
#define __NEED_time_t
#define __NEED_struct_timeval

#include <bits/alltypes.h>

struct utmpx
{
	short ut_type;
	pid_t ut_pid;
	char ut_line[32];
	char ut_id[4];
	char ut_user[32];
	char ut_host[256];
	struct {
		short __e_termination;
		short __e_exit;
	} __ut_exit;
	long ut_session;
	struct timeval ut_tv;
	unsigned ut_addr_v6[4];
	char __unused[20];
};

void          endutxent(void);
struct utmpx *getutxent(void);
struct utmpx *getutxid(const struct utmpx *);
struct utmpx *getutxline(const struct utmpx *);
struct utmpx *pututxline(const struct utmpx *);
void          setutxent(void);

#define EMPTY           0
#define BOOT_TIME       2
#define NEW_TIME        3
#define OLD_TIME        4
#define INIT_PROCESS    5
#define LOGIN_PROCESS   6
#define USER_PROCESS    7
#define DEAD_PROCESS    8

#ifdef __cplusplus
}
#endif

#endif
