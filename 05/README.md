# [bootstrap](../README.md) stage 05

This stage consists of a C compiler capable of compiling TCC (after some modifications
to TCC's source code).
Run

```
make
```

to build our C compiler and TCC. This will take some time (approx. 25 seconds on my computer).
A test program, `test.out` will be compiled using `tcc`. If you run
it, you should get the output

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

## limitations

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

