#ifndef _SIGNAL_H
#define _SIGNAL_H


#include <stdc_common.h>

typedef long sig_atomic_t; // there are no "asynchronous interrupts"

#define SIG_DFL ((void *)0)
#define SIG_IGN _sig_ign
#define SIG_ERR ((void *)-1)

typedef void (*_Sighandler)(int);

struct sigaction {
	void (*sa_handler)(int);
	#define sa_sigaction sa_handler
	unsigned long sa_flags;
	void (*sa_restorer)(void);
	unsigned long sa_mask;
};

unsigned char _signal_restorer[] = {
	0x48,0xb8,15,0,0,0,0,0,0,0, // mov rax, 15 (sigreturn)
	0x0f,0x05 // syscall
};

#define _SIGNAL_HANDLERS 0xfff000
#define _LE64(x) (x)&0xff,       ((x)>> 8)&0xff, ((x)>>16)&0xff, ((x)>>24)&0xff, \
                 ((x)>>32)&0xff, ((x)>>40)&0xff, ((x)>>48)&0xff, (x)>>56

// we need to do this weird indirection because linux has a different
// calling convention from us.

unsigned char _signal_handler[] = {
	// signal # passed in rdi
	0x48,0x89,0xf8,                     // mov rax, rdi (signal #)
	0x50,                               // push rax
	0x50,                               // push rax (allocate space for return value)
	0x48,0xb8,_LE64(_SIGNAL_HANDLERS),  // mov rax, _SIGNAL_HANDLERS
	0x48,0x89,0xc3,                     // mov rbx, rax
	0x48,0x89,0xf8,                     // mov rax, rdi (signal #)
	0x48,0xc1,0xe0,0x03,                // shl rax, 3
	0x48,0x01,0xd8,                     // add rax, rbx
	0x48,0x89,0xc3,                     // mov rbx, rax
	0x48,0x8b,0x03,                     // mov rax, [rbx]
	0xff,0xd0,                          // call rax
	0x48,0x81,0xc4,16,0,0,0,            // add rsp, 16
	0xc3                                // ret
};

#define _SA_RESTORER 0x04000000
#define SA_SIGINFO 4
#define SA_RESETHAND 0x80000000

int __sigaction(int signum, const struct sigaction *act, struct sigaction *oldact) {
	return __syscall(13, signum, act, oldact, 8, 0, 0);
}

void sigemptyset(unsigned long *set) {
	*set = 0;
}

void _sig_ign(int signal) {
	return;
}

static unsigned long _sig_mask = 0;

_Sighandler signal(int sig, _Sighandler func) {
	void **handlers = _SIGNAL_HANDLERS;
	_Sighandler ret = handlers[sig];
	if (func == SIG_IGN) {
		func = _sig_ign;
	}
	handlers[sig] = func;
	
	if (func == SIG_DFL) {
		_sig_mask &= ~(1ul << (sig-1));
	} else {
		_sig_mask |= 1ul << (sig-1);
	}
	struct sigaction act = {0};
	act.sa_handler = func == SIG_DFL ? SIG_DFL : (void*)_signal_handler;
	act.sa_mask = _sig_mask;
	act.sa_flags = _SA_RESTORER;
	act.sa_restorer = _signal_restorer;
	__sigaction(sig, &act, NULL);
	return ret;
}

int raise(int signal) {
	return kill(getpid(), signal);
}

#define FPE_INTDIV 1
#define FPE_FLTDIV 3

#define __SI_MAX_SIZE	128
#if __WORDSIZE == 64
# define __SI_PAD_SIZE	((__SI_MAX_SIZE / sizeof (int)) - 4)
#else
# define __SI_PAD_SIZE	((__SI_MAX_SIZE / sizeof (int)) - 3)
#endif

#ifndef __SI_ALIGNMENT
# define __SI_ALIGNMENT		/* nothing */
#endif
#ifndef __SI_BAND_TYPE
# define __SI_BAND_TYPE		long int
#endif
#ifndef __SI_CLOCK_T
# define __SI_CLOCK_T		__clock_t
#endif
#ifndef __SI_ERRNO_THEN_CODE
# define __SI_ERRNO_THEN_CODE	1
#endif
#ifndef __SI_HAVE_SIGSYS
# define __SI_HAVE_SIGSYS	1
#endif
#ifndef __SI_SIGFAULT_ADDL
# define __SI_SIGFAULT_ADDL	/* nothing */
#endif

typedef int __pid_t;
typedef unsigned __uid_t;

union __sigval
{
  int __sival_int;
  void *__sival_ptr;
};

typedef union __sigval __sigval_t;
typedef long __clock_t;

typedef struct
  {
    int si_signo;		/* Signal number.  */
#if __SI_ERRNO_THEN_CODE
    int si_errno;		/* If non-zero, an errno value associated with
				   this signal, as defined in <errno.h>.  */
    int si_code;		/* Signal code.  */
#else
    int si_code;
    int si_errno;
#endif
#if __WORDSIZE == 64
    int __pad0;			/* Explicit padding.  */
#endif

    union
      {
	int _pad[__SI_PAD_SIZE];

	 /* kill().  */
	struct
	  {
	    __pid_t si_pid;	/* Sending process ID.  */
	    __uid_t si_uid;	/* Real user ID of sending process.  */
	  } _kill;

	/* POSIX.1b timers.  */
	struct
	  {
	    int si_tid;		/* Timer ID.  */
	    int si_overrun;	/* Overrun count.  */
	    __sigval_t si_sigval;	/* Signal value.  */
	  } _timer;

	/* POSIX.1b signals.  */
	struct
	  {
	    __pid_t si_pid;	/* Sending process ID.  */
	    __uid_t si_uid;	/* Real user ID of sending process.  */
	    __sigval_t si_sigval;	/* Signal value.  */
	  } _rt;

	/* SIGCHLD.  */
	struct
	  {
	    __pid_t si_pid;	/* Which child.	 */
	    __uid_t si_uid;	/* Real user ID of sending process.  */
	    int si_status;	/* Exit value or signal.  */
	    __SI_CLOCK_T si_utime;
	    __SI_CLOCK_T si_stime;
	  } _sigchld;

	/* SIGILL, SIGFPE, SIGSEGV, SIGBUS.  */
	struct
	  {
	    void *si_addr;	    /* Faulting insn/memory ref.  */
	    __SI_SIGFAULT_ADDL
	    short int si_addr_lsb;  /* Valid LSB of the reported address.  */
	    union
	      {
		/* used when si_code=SEGV_BNDERR */
		struct
		  {
		    void *_lower;
		    void *_upper;
		  } _addr_bnd;
		/* used when si_code=SEGV_PKUERR */
		uint32_t _pkey;
	      } _bounds;
	  } _sigfault;

	/* SIGPOLL.  */
	struct
	  {
	    __SI_BAND_TYPE si_band;	/* Band event for SIGPOLL.  */
	    int si_fd;
	  } _sigpoll;

	/* SIGSYS.  */
#if __SI_HAVE_SIGSYS
	struct
	  {
	    void *_call_addr;	/* Calling user insn.  */
	    int _syscall;	/* Triggering system call number.  */
	    unsigned int _arch; /* AUDIT_ARCH_* of syscall.  */
	  } _sigsys;
#endif
      } _sifields;
  } siginfo_t __SI_ALIGNMENT;


/* X/Open requires some more fields with fixed names.  */
#define si_pid		_sifields._kill.si_pid
#define si_uid		_sifields._kill.si_uid
#define si_timerid	_sifields._timer.si_tid
#define si_overrun	_sifields._timer.si_overrun
#define si_status	_sifields._sigchld.si_status
#define si_utime	_sifields._sigchld.si_utime
#define si_stime	_sifields._sigchld.si_stime
#define si_value	_sifields._rt.si_sigval
#define si_int		_sifields._rt.si_sigval.sival_int
#define si_ptr		_sifields._rt.si_sigval.sival_ptr
#define si_addr		_sifields._sigfault.si_addr
#define si_addr_lsb	_sifields._sigfault.si_addr_lsb
#define si_lower	_sifields._sigfault._bounds._addr_bnd._lower
#define si_upper	_sifields._sigfault._bounds._addr_bnd._upper
#define si_pkey		_sifields._sigfault._bounds._pkey
#define si_band		_sifields._sigpoll.si_band
#define si_fd		_sifields._sigpoll.si_fd
#if __SI_HAVE_SIGSYS
# define si_call_addr	_sifields._sigsys._call_addr
# define si_syscall	_sifields._sigsys._syscall
# define si_arch	_sifields._sigsys._arch
#endif


#endif // _SIGNAL_H
