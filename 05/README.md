# [bootstrap](../README.md) stage 05

This stage consists of a C compiler capable of compiling TCC (after some modifications
to TCC's source code).
Run

```
make
```

to build our C compiler and TCC. This will take some time (approx. 25 seconds on my computer).
Two test programs will be produced: `a.out`, compiled using our C compiler, and
`test.out`, compiled using `tcc`. If you run either one, you should get the output

```
Hello, world!
```

## the C compiler

The C compiler for this stage is written in the [04 language](../04/README.md), using the [04a preprocessor](../04a/README.md)
and is spread out across multiple files:

```
util.b         - various utilities (syscall, puts, memset, etc.)
constants.b    - numerical and string constants used by the rest of the program
idents.b       - functions for creating mappings from identifiers to arbitrary 64-bit values
preprocess.b   - preprocesses C files
tokenize.b     - turns preprocessing tokens into tokens (see explanation below)
parse.b        - turns tokens into a nice representation of the program
codegen.b      - turns parse.b's representation into actual code
main.b         - puts everything together
```

The whole thing is ~12,000 lines of code, which is ~280KB when compiled.

### the C standard

In 1989, the C programming language was standardized by the [ANSI](https://en.wikipedia.org/wiki/American_National_Standards_Institute).

The C89 standard (in theory) defines which C programs are legal, and exactly what any particular legal C program does.
A draft of it, which is about as good as the real thing, is [available here](http://port70.net/~nsz/c/c89/c89-draft.html).

Since 1989, more features have been added to C, and so more C standards have been published.
To keep things simple, our compiler only supports the features from C89 (with a few exceptions).


### compiling a C program

Compiling a C program involves several "translation phases" (C89 standard § 2.1.1.2).
Here, I'll only be outlining the process our C compiler uses. The technical details
of the standard are slightly different.

First, each time a backslash is immediately followed by a newline, both are deleted, e.g.
```
Hel\
lo,
wo\
rld!
```
becomes
```
Hello,
world!
```
Well, we actually turn this into
```
Hello,

world!

```
so that line numbers are preserved for errors (this doesn't change the meaning of any program).
This feature exists so that you can spread one line of code across multiple lines, which is useful sometimes.

Then, comments are deleted (technically, replaced with spaces), and the file is split up into
*preprocesing tokens*. A preprocessing token is one of:

- A number (e.g. `5`, `10.2`, `3.6.6`)
- A string literal (e.g. `"Hello"`)
- A symbol (e.g. `<`, `{`, `.`)
- An identifier (e.g. `int`, `x`, `main`)
- A character constant (e.g. `'a'`, `'\n'`)
- A space character
- A newline character

Note that preprocessing tokens are just strings of characters, and aren't assigned any meaning yet; `3.6.6e-.3` is a valid
"preprocessing number" even though it's gibberish.

Next, preprocessor directives are executed. These include things like
```
#define A_NUMBER 4
```
which will replace every preprocessing token consisting of the identifier `A_NUMBER` in the rest of the program with `4`. Also in this phase,
```
#include "X"
```
is replaced with the (preprocessing tokens in the) file named `X`.

Then preprocessing tokens are turned into *tokens*.
Tokens are one of:

- A keyword (e.g. `int`, `while`)
- A symbol (e.g. `<`, `-`, `{`)
- An identifier (e.g. `main`, `f`, `x_3`)
- An integer literal (e.g. `77`, `0x123`)
- A character literal (e.g. `'a'`, `'\n'`)
- A floating-point literal (e.g. `3.6`, `5e10`)

Next, an internal representation of the program is constructed in memory.
This is where we read the tokens `if` `(` `a` `)` `printf` `(` `"Hello!\n"` `)` `;`
and interpret it as an if statement, whose condition is the variable `a`, and whose
body consists of the single statement calling the `printf` function with the argument `"Hello!\n"`.

Finally, we output the code for every function.

## executable format

This compiler's executables are much more sophisticated than the previous ones'.
Instead of storing code and data all in one segment, we have three segments: one
6MB segment for code (the program's functions are only allowed to use up 4MB of that, though),
one 4MB segment for read-only data (strings), and one 4MB segment for read-write data.

Well, it *should* only be read-write, but unfortunately it also has to be executable...

## syscalls

Of course, we need some way of making system calls in C.
We do this with a macro, `__syscall`, which you'll find in `stdc_common.h`:

```
static unsigned char __syscall_data[] = {
	// mov rax, [rsp+24]
	0x48, 0x8b, 0x84, 0x24, 24, 0, 0, 0,
	// mov rdi, rax
	0x48, 0x89, 0xc7,
	// mov rax, [rsp+32]
	0x48, 0x8b, 0x84, 0x24, 32, 0, 0, 0,
	// mov rsi, rax
	0x48, 0x89, 0xc6,
	// mov rax, [rsp+40]
	0x48, 0x8b, 0x84, 0x24, 40, 0, 0, 0,
	// mov rdx, rax
	0x48, 0x89, 0xc2,
	// mov rax, [rsp+48]
	0x48, 0x8b, 0x84, 0x24, 48, 0, 0, 0,
	// mov r10, rax
	0x49, 0x89, 0xc2,
	// mov rax, [rsp+56]
	0x48, 0x8b, 0x84, 0x24, 56, 0, 0, 0,
	// mov r8, rax
	0x49, 0x89, 0xc0,
	// mov rax, [rsp+64]
	0x48, 0x8b, 0x84, 0x24, 64, 0, 0, 0,
	// mov r9, rax
	0x49, 0x89, 0xc1,
	// mov rax, [rsp+16]
	0x48, 0x8b, 0x84, 0x24, 16, 0, 0, 0,
	// syscall
	0x0f, 0x05,
	// mov [rsp+8], rax
	0x48, 0x89, 0x84, 0x24, 8, 0, 0, 0,
	// ret
	0xc3
};

#define __syscall(no, arg1, arg2, arg3, arg4, arg5, arg6)\
	(((unsigned long (*)(unsigned long, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long, unsigned long))__syscall_data)\
		(no, arg1, arg2, arg3, arg4, arg5, arg6))
```

The `__syscall_data` array contains machine language instructions which perform a system call, and the
`__syscall` macro "calls" the array as if it were a function. This is why we need a read-write-executable data
segment -- otherwise we'd need to implement system calls in the compiler.

## C standard library

The C89 standard specifies a bunch of "standard library" functions which any implementation has to make available, e.g.
`printf()`, `atoi()`, `exit()`.
Fortunately, we don't have to write these functions in the 04 language; we can write them in C.

To use a particular function, a C program needs to include the appropriate header file, e.g.
`#include <stdio.h>` lets you use `printf()` and other I/O-related functions. Normally,
these header files just declare what types the parameters to the functions should be,
but we actually put the function implementations there.

Let's take a look at the contents of `ctype.h`, which provides the functions `islower`, `isupper`, etc.:
```
#ifndef _CTYPE_H
#define _CTYPE_H

#include <stdc_common.h>

int islower(int c) {
	return c >= 'a' && c <= 'z';
}

int isupper(int c) {
	return c >= 'A' && c <= 'Z';
}

int isalpha(int c) {
	return isupper(c) || islower(c);
}

int isalnum(int c) {
	return isalpha(c) || isdigit(c);
}

...

#endif
```
The first two lines and last line prevent problems when the file is included multiple times.
We begin by including `stdc_common.h`, which has a bunch of functions and type definitions which all
our header files use, and then we define each of the necessary C standard library functions.


## limitations

There are various minor ways in which this compiler doesn't actually handle all of C89.
Here is a list of things we do wrong (this list is probably missing things, though):

- [trigraphs](https://en.wikipedia.org/wiki/Digraphs_and_trigraphs#C) are not handled
- `char[]` string literal initializers can't contain null characters (e.g. `char x[] = "a\0b";` doesn't work)
- you can only access members of l-values (e.g. `int x = function_which_returns_struct().member` doesn't work)
- no default-int (this is a legacy feature of C, e.g. `main() { }` can technically stand in for `int main() {}`)
- the keyword `auto` is not handled (again, a legacy feature of C)
- `default:` must be the last label in a switch statement.
- external variable declarations are ignored (e.g. `extern int x; int main() { return x; }  int x = 5; ` doesn't work)
- `typedef`s, and `struct`/`union`/`enum` declarations aren't allowed inside functions
- conditional expressions aren't allowed inside `case` (horribly, `switch (x) { case 5 ? 6 : 3: ; }` is legal C).
- bit-fields aren't handled
- Technically, `1[array]` is equivalent to `array[1]`, but we don't handle that.
- C89 has *very* weird typing rules about `void*`/`non-void*` inside conditional expressions. We don't handle that properly.
- C89 allows calling functions without declaring them, for legacy reasons. We don't handle that.
- Floating-point constant expressions are very limited. Only `double` literals and 0 are supported (it was hard enough
to parse floating-point literals in a language without floating-point variables!)
- Floating-point literals can't have their integer part greater than 2<sup>64</sup>-1.
- Redefining a macro is always an error, even if it's the same definition.
- You can't have a variable/function/etc. called `defined`.
- Various little things about when macros are evaluated in some contexts.
setjmp.h:// @NONSTANDARD: we don't actually support setjmp
stddef.h:// @NONSTANDARD: we don't have wchar_t
stdlib.h:// @NONSTANDARD: we don't define MB_CUR_MAX or any of the mbtowc functions
time.h:// @NONSTANDARD(except in UTC+0): we don't support local time in timezones other than UTC+0.
time.h: // @NONSTANDARD-ish.


Also, the keywords `signed`, `volatile`, `register`, and `const` are all ignored. This shouldn't have an effect
on any legal C program, though.

## modifications of tcc's source code


## the nightmare begins

So now we just compile TCC with itself, and we're done, right?
Well, not quite...

The issue here is that to compile TCC/GCC with TCC, we need libc, the C standard library functions.
Our C compiler just includes these functions in the standard header files, but normally
the code for them is located in a separate library file (called something like
`/usr/lib/x86_64-linux-gnu/libc-2.31.so`).

This library file is itself compiled from C source files (typically glibc).
So, can't we just compile glibc with TCC, then compile TCC with itself?
Well, no. Compiling glibc with TCC is basically impossible; you need to compile
it with GCC.

Other libc implementations aren't too happy about TCC either -- I tried to compile
[musl](http://www.musl-libc.org/) for several hours, and had to give up in the end.

It seems that the one option left is to make our own libc, and try to use it along with
TCC to compile GCC.
From there, we should be able to compile glibc with GCC. Then, we can compile GCC with GCC and glibc.
If we do all this, we should get the same libc.so and gcc files as if we had started
with any GCC and glibc builds. It's all very confusing.

