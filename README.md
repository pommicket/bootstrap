# boostrapping a (Linux x86-64) C compiler

Compilers nowadays are written in languages like C, which themselves need to be
compiled. But then, you need a C compiler to compile your C compiler! Of course,
the very first C compiler was not written in C (because how would it be
compiled?). Instead, it was built up over time, starting from a basic
assembler, eventually reaching a full-scale compiler.
In this repository, we'll explore how that's done. Each directory
represents a new "stage" in the process. The first one, `00`, is a hand-written
executable, and the last one will be a C compiler. Each directory has its own
README explaining what's going on.

You can run `bootstrap.sh` to run through and test every stage.
To get HTML versions of all README pages, run `make`.

Note that the executables produced in this series will only run on 
64-bit Linux, because each OS/architecture combination would need its own separate
executable.

## table of contents

- [stage 00](00/README.md) - a program converting a text file with 
hexadecimal digit pairs to a binary file.
- [stage 01](01/README.md) - a language with comments, and 2-character
command codes.
- [stage 02](02/README.md) - a language with labels
- [stage 03](03/README.md) - a language with longer labels, better error messages, and less register manipulation
- [stage 04](04/README.md) - a language with nice functions and local variables
- [stage 04a](04a/README.md) - (interlude) a simple preprocessor
- more coming soon (hopefully)

## prerequisite knowledge

In this series, I want to *everything* that's going on to be understandable. I'm going to
need to assume some passing knowledge, so here's a quick overview of what you'll
want to know before starting.
You don't need to understand everything about each of these, just get
a general idea:

- the basics of programming
- what a system call is
- what memory is
- what a compiler is
- what an executable file is
- number bases -- if a number is preceded by 0x, 0o, or 0b in this series, that
means hexadecimal/octal/binary respectively. So 0xff = FF hexadecimal = 255
decimal.
- what a CPU is
- what a CPU architecture is
- what a CPU register is
- what the (call) stack is
- bits, bytes, kilobytes, etc.
- bitwise operations (not, or, and, xor, left shift, right shift)
- 2's complement
- ASCII, null-terminated strings
- how pointers work
- how floating-point numbers work

If you aren't familiar with x86-64 assembly, be sure to check out the instruction list
below.

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
This is one of the inspirations for this project. To summarize
the article: it is possible to create a malicious C compiler which will
replicate its own malicious functionalities (e.g. detecting password-checking
routines to make them also accept another password the attacker knows) when used
to compile other C compilers. For all we know, such a compiler was used to
compile GCC, say, and so all programs around today could be compromised. Of
course, this is practically definitely not the case, but it's still an
interesting experiment to try to create a fully trustable compiler.  This
project can't necessarily even do that though, because the Linux kernel, which
we depend on, is compiled from C, so we can't fully trust *it*. To
create a *fully* trustable compiler, you'd need to manually write 
an operating system to a USB key with a circuit or something,
assuming you trust your CPU...
I'll leave that to someone else.

## instruction set

x86-64 has a *gigantic* instruction set. The manual for it is over 2,000 pages
long! To make things simpler, we will only use a small subset.

Here are all the instructions we'll be using. If you're not familiar with
x86-64 assembly, you might want to look over these (but you don't need to understand everything).

In the table below, `IMM64` means a 64-bit *immediate* (a constant number).
`rdx:rax` refers to the 128-bit number you get by combining `rdx` and `rax`.

```
ax  bx  cx  dx  sp  bp  si  di
0   3   1   2   4   5   6   7

┌──────────────────────┬───────────────────┬────────────────────────────────────────┐
│ Instruction          │ Encoding          │ Description                            │
├──────────────────────┼───────────────────┼────────────────────────────────────────┤
│ mov rax, IMM64       │ 48 b8 IMM64       │ set rax to the 64-bit value IMM64      │
│ mov rbx, IMM64       │ 48 bb IMM64       │ set rbx to the 64-bit value IMM64      │
│ xor eax, eax         │ 31 c0             │ set rax to 0 (shorter than mov rax, 0) │
│ xor edx, edx         │ 31 d2             │ set rdx to 0                           │
│ mov RDEST, RSRC      │ 48 89 (DEST|SRC<<3|0xc0) │ set register DEST to current    │
│                      │                          │ value of register SRC           │
│ mov r8, rax          │ 49 89 c0          │ set r8 to rax (only used for syscalls) │
│ mov r9, rax          │ 49 89 c1          │ set r9 to rax (only used for syscalls) │
│ mov r10, rax         │ 49 89 c2          │ set r10 to rax (only used for syscalls)│
| movsx rax, al        | 48 0f be c0       | sign-extend al to rax                  |
| movsx rax, ax        | 48 0f bf c0       | sign-extend ax to rax                  |
| movsx rax, eax       | 48 63 c0          | sign-extend eax to rax                 |
| movzx rax, al        | 48 0f b6 c0       | zero-extend al to rax                  |
| movzx rax, ax        | 48 0f b7 c0       | zero-extend ax to rax                  |
| mov eax, eax         | 89 c0             | zero-extend eax to rax                 |
│ xchg rax, rbx        │ 48 93             │ exchange the values of rax and rbx     │
│ mov [rbx], rax       │ 48 89 03          │ store rax as 8 bytes at address rbx    │
│ mov rax, [rbx]       │ 48 8b 03          │ load 8 bytes from address rbx into rax │
│ mov [rbx], eax       │ 89 03             │ store eax as 4 bytes at address rbx    │
│ mov eax, [rbx]       │ 8b 03             │ load 4 bytes from address rbx into eax │
│ mov [rbx], ax        │ 66 89 03          │ store ax as 2 bytes at address rbx     │
│ mov ax, [rbx]        │ 66 8b 03          │ load 2 bytes from address rbx into eax │
│ mov [rbx], al        │ 88 03             │ store al as 1 byte at address rbx      │
│ mov al, [rbx]        │ 8a 03             │ load 1 byte from address rbx into al   │
│ mov rax, [rbp+IMM32] │ 48 8b 85 IMM32    │ load 8 bytes from address rbp+IMM32    │
│                      │                   │ into rax (note: IMM32 may be negative) │
│ mov rax, [rsp+IMM32] │ 48 8b 84 24 IMM32 │ load 8 bytes from address rsp+IMM32    │
│                      │                   │ into rax (note: IMM32 may be negative) │
│ mov [rbp+IMM32], rax │ 48 89 85 IMM32    │ store rax in 8 bytes at rbp+IMM32      │
│ mov [rsp+IMM32], rax │ 48 89 84 24 IMM32 │ store rax in 8 bytes at rsp+IMM32      │
│ mov [rsp], rbp       │ 48 89 2c 24       │ store rbp in 8 bytes at rsp            │
│ mov rbp, [rsp]       │ 48 8b 2c 24       │ load 8 bytes from rsp into rbp         │
│ lea rax, [rbp+IMM32] │ 48 8d 85 IMM32    │ set rax to rbp+IMM32                   │
│ lea rsp, [rbp+IMM32] │ 48 8d a5 IMM32    │ set rsp to rbp+IMM32                   │
| movsq                | 48 a5             | copy 8 bytes from rsi to rdi           |
| rep movsb            | f3 a4             | copy rcx bytes from rsi to rdi         |
│ push rax             │ 50                │ push rax onto the stack                │
│ pop rax              │ 58                │ pop a value off the stack into rax     │
│ neg rax              │ 48 f7 d8          │ set rax to -rax                        │
│ add rax, rbx         │ 48 01 d8          │ add rbx to rax                         │
│ sub rax, rbx         │ 48 29 d8          │ subtract rbx from rax                  │
│ imul rbx             │ 48 f7 eb          │ set rdx:rax to rax * rbx (signed)      │
│ cqo                  │ 48 99             │ sign-extend rax to rdx:rax             |
│ idiv rbx             │ 48 f7 fb          │ divide rdx:rax by rbx (signed); put    │
│                      │                   │    quotient in rax, remainder in rbx   │
│ mul rbx              │ 48 f7 e3          │ like imul, but unsigned                │
│ div rbx              │ 48 f7 f3          │ like idiv, but with unsigned division  │
│ not rax              │ 48 f7 d0          │ set rax to ~rax (bitwise not)          │
│ and rax, rbx         │ 48 21 d8          │ set rax to rax & rbx (bitwise and)     │
│ or rax, rbx          │ 48 09 d8          │ set rax to rax | rbx (bitwise or)      │
│ xor rax, rbx         │ 48 31 d8          │ set rax to rax ^ rbx (bitwise xor)     │
│ shl rax, cl          │ 48 d3 e0          │ set rax to rax << cl (left shift)      │
│ shl rax, IMM8        │ 48 c1 e0 IMM8     │ set rax to rax << IMM8                 │
│ shr rax, cl          │ 48 d3 e8          │ set rax to rax >> cl (zero-extend)     │
│ shr rax, IMM8        │ 48 c1 e8 IMM8     │ set rax to rax >> IMM8 (zero-extend)   │
│ sar rax, cl          │ 48 d3 f8          │ set rax to rax >> cl (sign-extend)     │
│ sar rax, IMM8        │ 48 c1 f8 IMM8     │ set rax to rax >> IMM8 (sign-extend)   │
│ sub rsp, IMM32       │ 48 81 ec IMM32    │ subtract IMM32 from rsp                │
│ add rsp, IMM32       │ 48 81 c4 IMM32    │ add IMM32 to rsp                       │
│ cmp rax, rbx         │ 48 39 d8          │ compare rax with rbx (see je, jl, etc.)│
│ test rax, rax        │ 48 85 c0          │ equivalent to cmp rax, 0               │
│ jmp IMM32            │ e9 IMM32          │ jump to offset IMM32 from here         │
│ je IMM32             │ 0f 84 IMM32       │ jump to IMM32 if equal                 │
│ jne IMM32            │ 0f 85 IMM32       │ jump if not equal                      │
│ jl IMM32             │ 0f 8c IMM32       │ jump if less than                      │
│ jg IMM32             │ 0f 8f IMM32       │ jump if greater than                   │
│ jle IMM32            │ 0f 8e IMM32       │ jump if less than or equal to          │
│ jge IMM32            │ 0f 8d IMM32       │ jump if greater than or equal to       │
│ jb IMM32             │ 0f 82 IMM32       │ jump if "below" (like jl but unsigned) │
│ ja IMM32             │ 0f 87 IMM32       │ jump if "above" (like jg but unsigned) │
│ jbe IMM32            │ 0f 86 IMM32       │ jump if below or equal to              │
│ jae IMM32            │ 0f 83 IMM32       │ jump if above or equal to              │
| movq rax, xmm0       | 66 48 0f 7e c0    | set rax to xmm0                        |
| movq xmm0, rax       | 66 48 0f 6e c0    | set xmm0 to rax                        |
| movq xmm1, rax       | 66 48 0f 6e c8    | set xmm1 to rax                        |
| movq xmm1, xmm0      | f3 0f 7e c8       | set xmm1 to xmm0                       |
| cvtss2sd xmm0, xmm0  | f3 0f 5a c0       | convert xmm0 from float to double      |
| cvtsd2ss xmm0, xmm0  | f2 0f 5a c0       | convert xmm0 from double to float      |
| cvttsd2si rax, xmm0  | f2 48 0f 2c c0    | convert double in xmm0 to int in rax   |
| cvtsi2sd xmm0, rax   | f2 48 0f 2a c0    | convert int in rax to double in xmm0   |
| comisd xmm0, xmm1    | 66 0f 2f c1       | compare xmm0 and xmm1                  |
| addsd xmm0, xmm1     | f2 0f 58 c1       | add xmm1 to xmm0                       |
| subsd xmm0, xmm1     | f2 0f 5c c1       | subtract xmm1 from xmm0                |
| mulsd xmm0, xmm1     | f2 0f 59 c1       | multiply xmm0 by xmm1                  |
| divsd xmm0, xmm1     | f2 0f 5e c1       | divide xmm0 by xmm1                    |
│ call rax             │ ff d0             │ call the function at address rax       │
│ ret                  │ c3                │ return from function                   │
│ syscall              │ 0f 05             │ execute a system call                  │
│ nop                  │ 90                │ do nothing                             │
└──────────────────────┴───────────────────┴────────────────────────────────────────┘
```

More will be added in the future as needed.

## license

```
This project is in the public domain. Any copyright protections from any law
are forfeited by the author(s). No warranty is provided, and the author(s)
shall not be held liable in connection with it.
```

## contributing

If you notice a mistake/want to clarify something, you can submit a pull request
via GitHub, or email `pommicket at pommicket.com`.
