# [bootstrap](../README.md) stage 05

This stage consists of a C compiler capable of compiling TCC (after some modifications
to TCC's source code).
Run

```
$ make
```

to build our C compiler and TCC. This will take some time (approx. 25 seconds on my computer).
This also compiles a "Hello, world!" executable, `a.out`, with our compiler.

We can now compile TCC with itself. But first, you'll need to install the header files and library files
which are needed to compile (almost) any program with TCC:

```
$ sudo make install-tcc0
```

The files will be installed to `/usr/local/lib/tcc-bootstrap`. If you want to change this, make sure to change
both the `TCCINST` variable in the makefile, and the `CONFIG_TCCDIR` macro in `config.h`.
Anyways, once this installation is done, you should be able to compile any C program with `tcc-0.9.27/tcc0`,
including TCC itself:

```
$ cd tcc-0.9.27
$ ./tcc0 tcc.c -o tcc1
```

Now, let's try doing the same thing, but starting with GCC instead of our C compiler:

```
$ gcc tcc.c -o tcc0a
$ ./tcc0a tcc.c -o tcc1a
```

In theory, these should produce the same files, since the output of TCC shouldn't depend on which compiler it was compiled with.
If they are different, then perhaps a bug *was* introduced in some early version of GCC, and replicated in all C compilers since then!
Well, only one way to find out:

```
$ diff tcc1 tcc1a
Binary files tcc1 and tcc1a differ
```

!!! Is there some malicious code hiding in the difference between these two files? Well unfortunately (fortunately, really) the
truth is more boring than that:

```
$ ./tcc1 tcc.c -o tcc2
$ diff tcc2 tcc1a
$
```

Yes, after compiling TCC with itself one more time, we get the same executable as the GCC-TCC one.
I'm not sure why `tcc1` differs from `tcc2`, but there you go. Turns out there isn't some malicious
self-replicating code hiding in GCC after all.\*

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

It can be compiled with `make` or:

```
../04a/out04 main.b in04
../04/out03 in04 out04
```

## the C standard

In 1989, the C programming language was standardized by the [ANSI](https://en.wikipedia.org/wiki/American_National_Standards_Institute).

The C89 standard (in theory) defines which C programs are legal, and exactly what any particular legal C program does.
A draft of it, which is about as good as the real thing, is [available here](http://port70.net/~nsz/c/c89/c89-draft.html).

Since 1989, more features have been added to C, and so more C standards have been published.
To keep things simple, our compiler only supports the features from C89 (with a few exceptions).


## compiler high-level details

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

Finally, we turn this internal representation into code for every function.

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
Here is a (probably incomplete) list of things we do wrong:

- [trigraphs](https://en.wikipedia.org/wiki/Digraphs_and_trigraphs#C) are not handled
- `char[]` string literal initializers can't contain null characters (e.g. `char x[] = "a\0b";` doesn't work)
- you can only access members of l-values (e.g. `int x = function_which_returns_struct().member;` doesn't work)
- no default-int (this is a legacy feature of C, e.g. `main() {}` can technically stand in for `int main() {}`)
- the keyword `auto` is not handled (again, a legacy feature of C)
- `default:` must come after all `case` labels in a switch statement.
- external variable declarations are ignored, and global variables can only be declared once
(e.g. `extern int x; int main() { return x; }  int x = 5; ` doesn't work)
- `typedef`s, and `struct`/`union`/`enum` definitions aren't allowed inside functions
- conditional expressions aren't allowed inside `case` (horribly, `switch (x) { case 5 ? 6 : 3: ; }` is legal C).
- bit-fields aren't handled
- Technically, `1[array]` is equivalent to `array[1]`, but we don't handle that.
- C89 has *very* weird typing rules about `void*`/`non-void*` inside conditional expressions. We don't handle that properly.
- C89 allows calling functions without declaring them, for legacy reasons. We don't handle that.
- Floating-point constant expressions are very limited. Only `double` literals and 0 are supported.
- In floating-point literals, the numbers before and after the decimal point must be less than 2<sup>64</sup>.
- The only "address constants" we allow are string literals, e.g. `int y, x = &y;` is not allowed as a global declaration.
- Redefining a macro is always an error, even if it's the same definition.
- You can't have a variable/function/etc. called `defined`.
- Various little things about when macros are evaluated in some contexts.
- The horrible, horrible function `setjmp`, which surely no one uses, is not properly supported.
Oh wait, TCC uses it. Fortunately it's not critically important to TCC.
- Wide characters and wide character strings are not supported.
- The `localtime()` function assumes you are in the UTC+0 timezone.
- `mktime()` always fails.
- The keywords `signed`, `volatile`, `register`, and `const` are all ignored, but this should almost never
have an effect on a legal C program.

## anecdotes

Making this C compiler took over a month. Here are some interesting things
which happened along the way:

- Writing code to parse floating-point numbers in a language which
doesn't have floats turned out to be quite a fun challenge!
Not all decimal numbers have a perfect floating point representation. You could
round 0.1 up to ~0.1000000000000000056, or down to ~0.0999999999999999917.
This stage's C compiler should be entirely correct, up to rounding (which is all that the
C standard requires).
But typically C compilers
will round to whichever is closest to the decimal value. Implementing this correctly
is a lot harder than you might expect. For example,
```
0.09999999999999999861222121921855432447046041488647460937499
rounds down, but
0.09999999999999999861222121921855432447046041488647460937501
rounds up.
```
Good luck writing a function which handles that!
- Originally, there was a bug where negative powers of 2 were
being interpreted as half of their actual value, e.g. `x = 0.25;` would set `x` to
`0.125`, but `x = 4;`, `x = 0.3;`, etc. would all work just fine.
- Writing the functions in `math.h`, although probably not necessary for compiling TCC,
was fun! There are quite a few interesting optimizations you can make, and little
tricks for avoiding losses in floating-point accuracy.
- The <s>first</s> second non-trivial program I successfully compiled worked perfectly the first time I ran it!
- A very difficult to track down bug happened the first time I ran `tcc`: there was a declaration along
the lines of `char x[] = "a\0b\0c";` but it got compiled as `char x[] = "a";`!
- Originally, I was just treating labels the same as any other statements, but `tcc` actually has code like:
```
...
goto lbl;
...
if (some_condition)
    lbl: do_something();
```
so the `do_something();` was not being considered as part of the `if` statement.
- The first time I compiled tcc with itself (and then with itself again), I actually got a different
executable from the GCC one. After spending a long time looking at disassemblies, I found the culprit:
```
# if defined(__linux__)
    tcc_define_symbol(s, "__linux__", NULL);
    tcc_define_symbol(s, "__linux", NULL);
# endif
```
If the `__linux__` macro is defined (to indicate that the target OS is linux),
TCC will also define the `__linux__` macro. Unlike GCC, our compiler doesn't define the `__linux__` macro,
so when it's used to compile TCC, TCC won't define it either, no matter how many times you compile it
with itself!

## modifications of tcc's source code

Some modifications were needed to bring tcc's source code in line with what our compiler expects.

You can find a full list of modifications in `diffs.txt`, but I'll provide an overview (and explanation)
here.

- First, we (and C89) don't allow a comma after the last member in an initializer. In several places,
the last comma in an initializer/enum definition was removed, or an irrelevant entry was added to the end.
- Global variables were sometimes declared twice, which we don't support.
So, a bunch of duplicate declarations were removed.
- The `# if defined(__linux__)` and `# endif` mentioned above were removed.
- In a bunch of places, `ELFW(something)` had to be replaced with `ELF64_something` due to
subtleties of how we evaluate macros.
- `offsetof(type, member)` isn't considered a constant expression by our compiler, so
some initializers were replaced by functions called at the top of `main`.
- In several places, `default:` had to be moved to after every `case` label.
- In two places, `-some_long_double_expression` had to be replaced with
a function call to `negate_ld` (a function I wrote for negating long doubles).
This is because TCC only supports negating long doubles if
the compiler used to compile it has an 80-bit long double type, which our compiler doesn't.
- `\0` was replaced with `\n` as a separator for keyword names.
- Forced TCC to use `R_X86_64_PC32` relocations, because its `plt` code doesn't seem to work for static
executables.
- Lastly, there's the `config.h` file, which is normally produced by TCC's `configure` script,
but it's easy to write one manually:
```
#define TCC_VERSION "0.9.27"
#define CONFIG_TCC_STATIC 1
#define TCC_TARGET_X86_64 1
#define ONE_SOURCE 1
#define CONFIG_LDDIR "lib/x86_64-linux-gnu"
#define CONFIG_TCCDIR "/usr/local/lib/tcc-bootstrap"
#define inline
```
The last line causes the `inline` keyword (added in C99) to be ignored.

Fewer changes would've been needed for an older version of TCC, but older versions didn't support
x86-64 assembly, which might end up being relevant...

## \*the nightmare begins

If you look in TCC's source code, you will not find implementations of any of the C standard library functions.
So how can programs compiled with TCC use those functions?

When a program compiled with TCC (under default settings) calls `printf`, say, it actually gets the instructions
for `printf` from a separate library file
(called something like `/usr/lib/x86_64-linux-gnu/libc-2.31.so`). There are very good reasons for this: for example,
if there a security bug were found in `printf`, it would be much easier to replace the library file than re-compile
every program which uses `printf`.

Now this library file is itself compiled from C source files (typically glibc).
So, we can't really say that the self-compiled TCC was built from scratch. And there could be malicious
self-replicating code in glibc!

So, why not just compile glibc with TCC?
Well, it's not actually possible. glibc can pretty much only be compiled with GCC.
This stage's C compiler definitely can't compile GCC, so we'll need a libc implementation to
compile GCC. Hmm...

Other libc implementations don't seem to like TCC either, so it seems that the only option left is to
make a new libc implementation, use that to compile GCC (probably an old version of it which TCC can compile),
then use GCC to compile glibc. It will definitely be a large undertaking... 
