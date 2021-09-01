# boostrapping a (Linux x86-64) C compiler

Compilers nowadays are written in languages like C, which themselves need to be
compiled. But then, you need a C compiler to compile your C compiler! Of course,
the very first C compiler was not written in C (because how would it be
compiled?). Instead, it was slowly built up, starting from a very basic
assembler, eventually reacing a full-scale compiler. This process is known as
bootstrapping. In this repository, we'll explore how that's done. Each directory
represents a new "stage" in the process. The first one, `00`, is a hand-written
executable, and the last one will be a C compiler. Each directory has its own
README explaining what's going on.

You can run `bootstrap.sh` to run through and test every stage.
To get HTML versions of all README pages, run `make`.

## the basics

In this series, I want to explain *everything* that's going on. I'm going to
need to assume some passing knowledge, so here's a quick overview of what you'll
want to know before starting. I can't explain everything so you may need to do
your own research. You don't need to understand each of these in full, just get
a general idea at least:

- what an operating system is
- what memory is
- what a programming language is
- what a compiler is
- what an executable file is
- number bases -- if a number is preceded by 0x, 0o, or 0b in this series, that
means hexadecimal/octal/binary respectively. So 0xff = FF hexadecimal = 255
decimal.
- what a CPU is
- what a CPU architecture is
- what a CPU register is
- bits, bytes, kilobytes, etc.
- bitwise operations (not, or, and, xor, left shift, right shift)
- 2's complement
- null-terminated strings
- how pointers work
- how floating-point numbers work
- maybe some basic Intel-style x86-64 assembly (you can probably pick it up on
the way though)

It will help you a lot to know how to program (with any programming language),
but it's not strictly necessary.

## instruction set

x86-64 has a *gigantic* instruction set. The manual for it is over 2,000 pages
long! So, it makes sense to select only a small subset of it to use for all the
stages of our compiler. The set I've chosen can be found in `instructions.txt`.
I think it achieves a pretty good balance between having few enough
instructions to be manageable and having enough instructions to be useable.
To be clear, you don't need to read that file to understand the series, at least
not right away.

## principles

- as simple as possible

Bootstrapping a compiler is not an easy task, so we're trying to make it as easy
as possible. We don't even necessarily need a standard-compliant C compiler, we
only need enough to compile someone else's C compiler, specifically we'll be
using [TCC](https://bellard.org/tcc/) since it's written in standard C89.

- efficiency is not a concern

We will create big and slow executables, and that's okay. It doesn't really
matter if compiling TCC takes 8 as opposed to 0.01 seconds; once we compile TCC
with itself, we'll get the same executable either way.

## reflections on trusting trust

In 1984, Ken Thompson wrote the well-known article
[Reflections on Trusting Trust](http://users.ece.cmu.edu/~ganger/712.fall02/papers/p761-thompson.pdf).
This is one of the things that inspired me to start this project. To summarize
the article: it is possible to create a malicious C compiler which will
replicate its own malicious functionalities (e.g. detecting password-checking
routines to make them also accept another password the attacker knows) when used
to compile other C compilers. For all we know, such a compiler was used to
compile GCC, say, and so all programs around today could be compromised. Of
course, this is practically definitely not the case, but it's still an
interesting experiment to try to create a fully trustable compiler.  This
project can't necessarily even do that though, because the Linux kernel, which
we depend on, is compiled from C, so we can't fully trust *it*. To *truly*
create a fully trustable compiler, you'd need to manually write to a USB with a
circuit, create an operating system from nothing (without even a text editor),
and then follow this series, or maybe you don't even trust your CPU vendor...
I'll leave that to someone else

## license

```
This project is in the public domain. Any copyright protections from any law
for this project are forfeited by the author(s). No warranty is provided for
this project, and the author(s) shall not be held liable in connection with it.
```

## contributing

If you notice a mistake/want to clarify something, you can submit a pull request
via GitHub, or email `pommicket at pommicket.com`. Translations are welcome!
