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

So now we just compile TCC with itself, and we're done, right?
Well, not quite...

## the nightmare begins

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

