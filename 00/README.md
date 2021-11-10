# stage 00

This directory contains the file `hexcompile`, a handwritten executable. It
takes input file `in00` containing space/newline/(any character)-separated
hexadecimal digit pairs (e.g. `3f`) and outputs them as bytes to the file
`out00`. On 64-bit Linux, try running `./hexcompile` from this directory (I've
already provided an `in00` file, which you can take a look at), and you will get
a file named `out00` containing the text `Hello, world!`.  This stage
lets you use your favorite text editor to write executables
(which have bytes outside of ASCII/UTF-8).
I made `hexcompile` with a program called
[hexedit](https://github.com/pixel/hexedit),
which can be found in most Linux package managers.
The executable is just 632 bytes long.
Let's take a look at what's inside (`od -t x1
-An -v hexcompile`):

```
7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
02 00 3e 00 01 00 00 00 78 00 40 00 00 00 00 00
40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 40 00 38 00 01 00 00 00 00 00 00 00
01 00 00 00 07 00 00 00 78 00 00 00 00 00 00 00
78 00 40 00 00 00 00 00 00 00 00 00 00 00 00 00
00 02 00 00 00 00 00 00 00 02 00 00 00 00 00 00
00 10 00 00 00 00 00 00 48 b8 6d 02 40 00 00 00
00 00 48 89 c7 31 c0 48 89 c6 48 b8 02 00 00 00
00 00 00 00 0f 05 48 b8 72 02 40 00 00 00 00 00
48 89 c7 48 b8 41 02 00 00 00 00 00 00 48 89 c6
48 b8 ed 01 00 00 00 00 00 00 48 89 c2 48 b8 02
00 00 00 00 00 00 00 0f 05 48 b8 03 00 00 00 00
00 00 00 48 89 c7 48 89 c2 48 b8 6a 02 40 00 00
00 00 00 48 89 c6 31 c0 0f 05 48 89 c3 48 b8 03
00 00 00 00 00 00 00 48 39 d8 0f 8f 50 01 00 00
48 b8 6a 02 40 00 00 00 00 00 48 89 c3 31 c0 8a
03 48 89 c3 48 b8 39 00 00 00 00 00 00 00 48 39
d8 0f 8c 0f 00 00 00 48 b8 d0 ff ff ff ff ff ff
ff e9 0a 00 00 00 48 b8 a9 ff ff ff ff ff ff ff
48 01 d8 48 c1 e0 04 48 89 c7 48 b8 6b 02 40 00
00 00 00 00 48 89 c3 31 c0 8a 03 48 89 c3 48 b8
39 00 00 00 00 00 00 00 48 39 d8 0f 8c 0f 00 00
00 48 b8 d0 ff ff ff ff ff ff ff e9 0a 00 00 00
48 b8 a9 ff ff ff ff ff ff ff 48 01 d8 48 89 fb
48 09 d8 48 89 c3 48 b8 6c 02 40 00 00 00 00 00
48 93 88 03 48 b8 04 00 00 00 00 00 00 00 48 89
c7 48 b8 6c 02 40 00 00 00 00 00 48 89 c6 48 b8
01 00 00 00 00 00 00 00 48 89 c2 0f 05 e9 f7 fe
ff ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
31 c0 48 89 c7 48 b8 3c 00 00 00 00 00 00 00 0f
05 00 00 00 00 00 00 00 00 00 00 00 00 69 6e 30
30 00 6f 75 74 30 30 00
```

Okay, that doesn't tell us much. I'll annotate it below.

## ELF header
This header has a bunch of metadata about the executable.
Instead of reading my annotations, you can also run `readelf -a --wide
hexcompile` to get this information in a compact form.

- `7f 45 4c 46` Special identifier saying that this is an ELF file (ELF is the
format of almost all Linux executables)
- `02` 64-bit
- `01` Little-endian
- `01` ELF version 1 (there is no version 2 yet)
- `00 00 00 00 00 00 00 00 00` Reserved (not important yet, but may be in a later
version of ELF)
- `02 00` Object type = executable file (not a dynamic library/etc.)
- `3e 00` Architecture x86-64
- `01 00 00 00` Version 1 of ELF, again 
- `78 00 40 00 00 00 00 00` **Entry point of the executable** = 0x400078
- `40 00 00 00 00 00 00 00` Program header table offset in bytes from start of file
- `00 00 00 00 00 00 00 00` Section header table offset (we're not using sections)
- `00 00 00 00` Flags (not important to us)
- `40 00` The size of this header, in bytes = 64
- `38 00` Size of the program header = 56
- `01 00` Number of program headers = 1
- `00 00` Size of each section header (unused)
- `00 00` Number of section headers (unused)
- `00 00` Index of special .shstrtab section (unused)

You might notice that all the numbers are backwards, e.g. `38 00` for the number
0x0038 (56 decimal). This is because almost all modern architectures (including
x86-64) are little-endian, meaning that the *least significant byte* goes first,
and the most significant byte goes last.
There are reasons for this ([see here](https://en.wikipedia.org/wiki/Endianness#Optimization), for example, if you're interested).

## program header
The program header describes a segment of data that is loaded into memory when
the program starts. Normally, you would have more than one of these, maybe 
one for code, one for read-only data, and one for read-write data, but to
simplify things we've only got one, which we'll use for any code and data
we need. This means it'll have to be read-enabled, write-enabled, and
execute-enabled. Normally people don't do this, for security, but we won't worry
about that (don't compile any untrusted code with any compiler from this series!)
Without further ado, here's the contents of the program header:

- `01 00 00 00` Segment type 1 (this segment should be loaded into memory)
- `07 00 00 00` Flags = RWE (readable, writeable, and executable)
- `78 00 00 00 00 00 00 00` Offset in file = 120 bytes
- `78 00 40 00 00 00 00 00` Virtual address = 0x400078

**wait a minute, what's that?**

This is the virtual
memory address that the segment will be loaded to.
Nowadays, computers use virtual memory, meaning that
addresses in our program don't actually correspond to where the memory is
physically stored in RAM (the CPU translates between virtual and physical
addresses). There are many reasons for this: making sure each process has
its own memory space, memory protection, etc. You can read more about it
elsewhere.

- `00 00 00 00 00 00 00 00` Physical address (not applicable)
- `00 02 00 00 00 00 00 00` Size of this segment in the executable file = 512
bytes
- `00 02 00 00 00 00 00 00` Size of this segment when loaded into memory = also
512 bytes
- `00 10 00 00 00 00 00 00` Segment alignment = 4096 bytes

That last field, segment alignment, is needed, because on default-settings Linux
each page (block) of memory is 4096 bytes long, and has to start at an address
that is a multiple of 4096. Our program needs to be loaded into a memory page,
so its *virtual address* needs to be a multiple of 4096. We're using `0x400000`.
But wait! Didn't we use `0x400078` for the virtual address? Well, yes but that's
because the segment's data is loaded to address `0x400078`. The actual page
of memory that the OS will allocate for our segment will start at `0x400000`. The
reason we need to start `0x78` bytes in is that Linux expects the data in the
file to be at the same position in the page as when it will be loaded, and it
appears at offset `0x78` in our file.

## the code

Now we get to the actual code in our executable. We specified `0x400078` as the
*entry point* of our executable, which means that the program will start
executing from there. That virtual address corresponds to the start of the code
right here:

- `48 b8 6d 02 40 00 00 00 00 00` `mov rax, 0x40026d`
- `48 89 c7` `mov rdi, rax`
- `31 c0` `xor eax, eax` (shorter form of `mov rax, 0`)
- `48 89 c6` `mov rsi, rax`
- `48 b8 02 00 00 00 00 00 00 00` `mov rax, 2`
- `0f 05` `syscall`

Here we open our input file, `in00`.

These instructions execute syscall `2` with arguments `0x40026d`, `0`.
If you're familiar with C code, this is `open("in00", O_RDONLY)`.
A syscall is the mechanism which lets software ask the kernel to do things.
[Here](https://filippo.io/linux-syscall-table/) is a nice table of syscalls you
can look through if you're interested. You can also install
[strace](https://strace.io) (e.g. with
`sudo apt install strace`) and run `strace ./hexcompile` to see all the syscalls
our program does.
Syscall #2, on 64-bit Linux, is `open`. It's used to open a file. You can read
about it with `man 2 open`.
The first argument, `0x40026d`, is a pointer to some data at the very end of
this segment (see further down). Specifically, it holds the bytes
`69 6e 30 30 00`, the null-terminated ASCII string `"in00"`.
This indicates the name of the file. The second argument, `0`,
specifies that we will (only) be reading from this file. There is a third argument to
this syscall (we'll get to it later), but it's not applicable here so we don't
set it.

This call gives us back a *file descriptor*, a number which we can use to read from the
file, in register `rax`. But we don't actually need to look at what file
descriptor Linux gave us. This is because Linux assigns file descriptor numbers
sequentially, starting from
[0 for stdin, 1 for stdout, 2 for stderr](https://en.wikipedia.org/wiki/Standard_streams),
and then 3, 4, 5, ... for any files our program opens. So
this file, the first one our program opens, will have descriptor 3.

Now we open our output file:

- `48 b8 72 02 40 00 00 00 00 00` `mov rax, 0x400272`
- `48 89 c7` `mov rdi, rax`
- `48 b8 41 02 00 00 00 00 00 00` `mov rax, 0x241`
- `48 89 c6` `mov rsi, rax`
- `48 b8 ed 01 00 00 00 00 00 00` `mov rax, 0o755`
- `48 89 c2` `mov rdx, rax`
- `48 b8 02 00 00 00 00 00 00 00` `mov rax, 2`
- `0f 05` `syscall`

In C, this is `open("out00", O_WRONLY|O_CREAT|O_TRUNC, 0755)`.  This is quite
similar to our first call, with two important differences: first, we specify
`0x241` as the second argument. This tells Linux that we are writing to the
file (`O_WRONLY = 0x01`), that we want to create it if it doesn't exist
(`O_CREAT = 0x40`), and that we want to delete any previous contents it had
(`O_TRUNC = 0x200`). Secondly, we're setting the third argument this time.  It
specifies the permissions our file is created with (`0o755` means user
read/write/execute, group/other read/execute). This is not very important to
the actual execution of the program, so don't worry if you don't know 
about UNIX permissions.
Note that the output file's descriptor will be 4.

Now we can start reading from the file. We're going to loop back to this part of
the code every time we want to read a new hexadecimal number from the input
file.

- `48 b8 03 00 00 00 00 00 00 00` `mov rax, 3`
- `48 89 c7` `mov rdi, rax`
- `48 89 c2` `mov rdx, rax`
- `48 b8 6a 02 40 00 00 00 00 00` `mov rax, 0x40026a`
- `48 89 c6` `mov rsi, rax`
- `31 c0` `mov rax, 0`
- `0f 05` `syscall`

In C, this is `read(3, 0x40026a, 3)`. Here we call syscall #0, `read`, with
three arguments:

- `fd = 3` This is the descriptor number of our input file.
- `buf = 0x40026a` This is the memory address we want Linux to output the data
to.
- `count = 3` This is the number of bytes we want to read.

We're telling Linux to output to `0x40026a`, which is just a part of this
segment (see further down). Normally you would read to a different segment of
the program from where the code is, but we want this to be as simple as
possible.
The number of bytes *actually* read, taking into account that we might have
reached the end of the file, is stored in `rax`.

- `48 89 c3` `mov rbx, rax`
- `48 b8 03 00 00 00 00 00 00 00` `mov rax, 3`
- `48 39 d8` `cmp rax, rbx`
- `0f 8f 50 01 00 00` `jg +0x150 (0x400250)`

This tells the CPU to jump to a later part of the code (address `0x400250`) if 3
is greater than the number of bytes we got, in other words, if we reached the
end of the file. Note that we don't specifiy the *address* to jump to, but
instead the *relative address*, relative to the first byte after the jump
instruction (so here we're saying to jump `0x150` bytes forward). There are
reasons for this which I won't get into here.

- `48 b8 6a 02 40 00 00 00 00 00` `mov rax, 0x40026a`
- `48 89 c3` `mov rbx, rax`
- `31 c0` `mov rax, 0`
- `8a 03` `mov al, byte [rbx]`

Here we put the ASCII code of the first character read from the file into `rax`.
But now we need to turn the ASCII character code into the actual numerical value
of the hex digit.

- `48 89 c3` `mov rbx, rax`
- `48 b8 39 00 00 00 00 00 00 00` `mov rax, 0x39 ('9')`
- `48 39 d8` `cmp rax, rbx`
- `0f 8c 0f 00 00 00` `jl 0x400136`

This checks if the character code is greater than the character code for the
digit 9, and jumps to a different part of the code if so. This different part of
the code will handle the case of the hex digits `a` through `f`.

- `48 b8 d0 ff ff ff ff ff ff ff` `mov rax, -48`

Set `rax` to the two's complement representation of `-48`. This will be added to
the character code to get the numerical value of the digit (`0` has ASCII code
`48`).

- `e9 0a 00 00 00` `jmp 0x400140`

This skips over the `a`-`f` handling code (coming up next).

- `48 b8 a9 ff ff ff ff ff ff ff` `mov rax, -87`

If you add the ASCII code for `a` to `-87` you get `10`. Similarly, adding
`-87` to `f` gives you `15`. So this will convert between `a`-`f` digits and
numerical values.

- `48 01 d8` `add rax, rbx`

Okay, now we add `-48` or `-87` to the character code to get the numerical value
of the digit in `rax`, whether it was one of `0123456789` or `abcdef`.

- `48 c1 e0 04` `shl rax, 4`
- `48 89 c7` `mov rdi, rax`

Now we shift it left by 4 bits (multiply it by 16), because it's the first hex
digit, and store it away in `rdi`. The bottom 4 bits will be the second hex
digit in the digit pair, which we'll read now, via a very similar process to
the one above:

- `48 b8 6b 02 40 00 00 00 00 00` `mov rax, 0x40026b`
- `48 89 c3` `mov rbx, rax`
- `31 c0` `mov rax, 0`
- `8a 03` `mov al, byte [rbx]`
- `48 89 c3` `mov rbx, rax`
- `48 b8 39 00 00 00 00 00 00 00` `mov rax, 0x39 ('9')`
- `48 39 d8` `cmp rax, rbx`
- `0f 8c 0f 00 00 00` `jl 0x400180`
- `48 b8 d0 ff ff ff ff ff ff ff` `mov rax, -48`
- `e9 0a 00 00 00` `jmp 0x40018a`
- `48 b8 a9 ff ff ff ff ff ff ff` `mov rax, -87`
- `48 01 d8` `add rax, rbx`
- `48 89 fb` `mov rbx, rdi`
- `48 09 d8` `or rax, rbx`

Okay, now `rax` contains the byte specified by the two hex digits we read.

- `48 89 c3` `mov rbx, rax`
- `48 b8 6c 02 40 00 00 00 00 00` `mov rax, 0x40026c`
- `48 93` `xchg rax, rbx`
- `88 03` `mov byte [rbx], al`

Put the byte in a specific memory location (address `0x40026c`).

- `48 b8 04 00 00 00 00 00 00 00` `mov rax, 4`
- `48 89 c7` `mov rdi, rax`
- `48 b8 6c 02 40 00 00 00 00 00` `mov rax, 0x40026c`
- `48 89 c6` `mov rsi, rax`
- `48 b8 01 00 00 00 00 00 00 00` `mov rax, 1`
- `48 89 c2` `mov rdx, rax`
- `0f 05` `syscall`

In C, this is `write(4, 0x40026c, 1)`.
This calls syscall #1, `write`, with arguments:

- `fd = 4` The file descriptor to write to.
- `buf = 0x40026c` Pointer to the data we want to write.
- `count = 1` The number of bytes to write.

- `e9 f7 fe ff ff` `jmp 0x4000c9`

This jumps way back in the program, to read the next digit pair from the input
file.

```
00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

These bytes aren't actually used by our program, and could be set to anything.
These are here because I wasn't sure how long the program would be when I
started, so I just set the segment size to 512 bytes, which turned out to be
more than enough. I could have cut these out and edited all the addresses to get
a smaller executable, but really there's no point—modern
computers can definitely handle 600-byte files.

- `31 c0` `mov rax, 0`
- `48 89 c7` `mov rdi, rax`
- `48 b8 3c 00 00 00 00 00 00 00` `mov rax, 60`
- `0f 05` `syscall`

This is where we conditionally jumped to way back when we determined if we
reached the end of the file. This calls syscall #60, `exit`, with one argument,
0 (exit code 0, indicating we exited successfully).

Normally, you would close files descriptors (with syscall #3), to tell Linux you're
done with them, but we don't need to. It'll automatically close all our open
file descriptors when our program exits.

- `00 00 00 00 00 00 00 00 00` (more unused bytes)

- `00 00 00` this is where we read data to, and wrote data from
- `69 6e 30 30 00` input filename, "in00"
- `6f 75 74 30 30 00` output filename, "out00"

That's quite a lot to take in for such a simple program, but here we are! We now
have something that will let us write individual bytes with an ordinary text
editor and get them translated into a binary file.

## limitations

There are many ways in which this is a bad program. It will *only* properly
handle lowercase hexadecimal digit pairs, separated by exactly one character,
with a terminating character. What's worse, a bad input file (maybe someone
accidentally writes `3F` instead of `3f`) won't print out a nice error message,
but instead continue processing as usual, without any indication that anything's
gone wrong, giving you an unexpected result.
Also, we only read in data *three bytes at a time*, and output one byte at a
time. This is a very bad idea because syscalls (e.g. `read`) are slow. `read`
might take ~3 microseconds, which doesn't sound like a lot, but it means that if
we used code like this to process a 50 megabyte file, say, we'd be waiting for
a while.

But these problems aren't really a big deal. We'll only be running this on
little programs and we'll be sure to check that our input is in the right
format. And with that, we are ready to move on to the
[next stage...](../01/README.md)
