--- boostrapping a (Linux x86-64) C compiler ---

Compilers nowadays are written in languages like C, which themselves need to be
compiled. But then, you need a C compiler to compile your C compiler! Of course,
the very first C compiler was not written in C (because how would it be
compiled?). Instead, it was slowly built up, starting from a very basic
assembler, eventually reacing a full-scale compiler. This process is known as
bootstrapping. In this repository, we'll explore how that's done. Each directory
represents a new "stage" in the process. The first one, "00", is a hand-written
executable, and the last one will be a C compiler. Each directory has its own
README.txt explaining in full what's going on.

-- instruction set --
x86-64 has a *gigantic* instruction set. The manual for it is over 2,000 pages
long! So, it makes sense to select only a small subset of it to use for all the
stages of our compiler. The set I've chosen can be found in instructions.txt (a
work in progress). I think it achieves a pretty good balance between 
having few enough instructions to be manageable and having enough
instructions to be useable.

-- license --

This software is in the public domain. Any copyright protections from any law
for this software are forfeited by the author(s). No warranty is provided for
this software, and the author(s) shall not be held liable in connection with it.
