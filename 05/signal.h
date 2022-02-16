#ifndef _SIGNAL_H
#define _SIGNAL_H


#include <stdc_common.h>

typedef long sig_atomic_t; // there are no "asynchronous interrupts"

#define SIG_DFL 0
#define SIG_IGN _sig_ign
#define SIG_ERR (-1)

typedef void (*_Sighandler)(int);

struct sigaction {
	void (*handler)(int);
	unsigned long flags;
	void (*restorer)(void);
	unsigned long mask;
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

int __sigaction(int signum, const struct sigaction *act, struct sigaction *oldact) {
	return __syscall(13, signum, act, oldact, 8, 0, 0);
}


void _sig_ign(int signal) {
	return;
}

static unsigned long _sig_mask = 0;

_Sighandler signal(int sig, _Sighandler func) {
	if (func == SIG_DFL) {
		// @TODO
		return 0;
	}
	if (func == SIG_IGN) {
		func = _sig_ign;
	}
	
	void **handlers = _SIGNAL_HANDLERS;
	handlers[sig] = func;
	
	_sig_mask |= 1ul << (sig-1);
	struct sigaction act = {0};
	act.handler = _signal_handler;
	act.mask = _sig_mask;
	act.flags = _SA_RESTORER;
	act.restorer = _signal_restorer;
	__sigaction(sig, &act, NULL);
	return 0;//@TODO
}

#endif // _SIGNAL_H
