# stage 00

This directory contains the file `hexcompile`, a handwritten executable. It
takes input file `A` containing space/newline/[any character]-separated
hexadecimal numbers and outputs them as bytes to the file `B`. On 64-bit Linux,
try running `./hexcompile` from this directory (I've already provided an `A`
file), and you will get a file named `B` containing the text `Hello, world!`.
This stage is needed so that you can use your favorite text editor to write
executables by hand (which have bytes outside of ASCII/UTF-8).  I wrote it with
a program called hexedit, which can be found on most Linux distributions. Only
64-bit Linux is supported, because each OS/architecture combination would need
its own separate executable. The executable is 632 bytes long, and you could
definitely make it smaller if you wanted to, especially if you didn't limit it
to the set of instructions I've decided on. Let's take a look at what's inside
(`od -t x1 -An hexcompile`):

```
7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
02 00 3e 00 01 00 00 00 78 00 40 00 00 00 00 00
40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 40 00 38 00 01 00 00 00 00 00 00 00
01 00 00 00 07 00 00 00 78 00 00 00 00 00 00 00
78 00 40 00 00 00 00 00 00 00 00 00 00 00 00 00
00 02 00 00 00 00 00 00 00 02 00 00 00 00 00 00
00 10 00 00 00 00 00 00 48 b8 74 02 40 00 00 00
00 00 48 89 c7 48 b8 00 00 00 00 00 00 00 00 48
89 c6 48 89 c2 48 b8 02 00 00 00 00 00 00 00 0f
05 48 89 c5 48 b8 76 02 40 00 00 00 00 00 48 89
c7 48 b8 41 00 00 00 00 00 00 00 48 89 c6 48 b8
a4 01 00 00 00 00 00 00 48 89 c2 48 b8 02 00 00
00 00 00 00 00 0f 05 48 89 ef 48 b8 68 02 40 00
00 00 00 00 48 89 c6 48 b8 03 00 00 00 00 00 00
00 48 89 c2 48 b8 00 00 00 00 00 00 00 00 0f 05
48 89 c3 48 b8 03 00 00 00 00 00 00 00 48 39 d8
0f 8f 37 01 00 00 48 b8 68 02 40 00 00 00 00 00
48 89 c3 48 8b 03 48 89 c3 48 89 c7 48 b8 ff 00
00 00 00 00 00 00 48 21 d8 48 89 c6 48 b8 39 00
00 00 00 00 00 00 48 89 c3 48 89 f0 48 39 d8 0f
8f 1e 00 00 00 48 b8 30 00 00 00 00 00 00 00 48
f7 d8 48 89 f3 48 01 d8 e9 26 00 00 00 00 00 00
00 00 00 48 b8 a9 ff ff ff ff ff ff ff 48 89 f3
48 01 d8 e9 0b 00 00 00 00 00 00 00 00 00 00 00
00 00 00 48 89 c2 48 b8 ff 00 00 00 00 00 00 00
48 89 c3 48 89 f8 48 c1 e8 08 48 21 d8 48 93 48
b8 39 00 00 00 00 00 00 00 48 93 48 39 d8 0f 8f
1f 00 00 00 48 89 c3 48 b8 d0 ff ff ff ff ff ff
ff 48 01 d8 e9 2a 00 00 00 00 00 00 00 00 00 00
00 00 00 48 89 c3 48 b8 a9 ff ff ff ff ff ff 48
01 d8 e9 0c 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 48 89 c7 48 89 d0 48 c1 e0 04 48 89 fb
48 09 d8 48 93 48 b8 68 02 40 00 00 00 00 00 48
93 48 89 03 48 89 de 48 b8 04 00 00 00 00 00 00
00 48 89 c7 48 b8 01 00 00 00 00 00 00 00 48 89
c2 0f 05 e9 8f fe ff ff 00 00 00 00 00 48 b8 3c
00 00 00 00 00 00 00 0f 05 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 41 00 42 00
```

Okay, that doesn't tell us much. I'll annotate it below. You might notice that
all the numbers are backwards, e.g. `3e 00` for the number 0x003e (62 decimal).
This is because almost all modern architectures (including x86-64) are
little-endian, meaning that the *least significant byte* goes first, and the
most significant byte goes last. There are various reasons why this is easier to
deal with, but I won't explain that here.

## ELF header
This header has a bunch of metadata about the executable.

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
- `78 00 40 00 00 00 00 00` **Entry point of the executable** = 0x400078 (explained later)
- `40 00 00 00 00 00 00 00` Program header table offset in bytes from start of file (see below)
- `00 00 00 00 00 00 00 00` Section header table offset (we're not using sections)
- `00 00 00 00` Flags (not important)
- `40 00` The size of this header, in bytes = 64
- `38 00` Size of the program header (see below) = 56
- `01 00` Number of program headers = 1
- `00 00` Size of each section header (unused)
- `00 00` Number of section headers (unused)
- `00 00` Index of special .shstrtab section (unused)

## program header
The program header describes a segment of data that is loaded into memory when
the program starts. Normally, you would have more than one of these, maybe 
one for code, one for read-only data, and one for read-write data, but to
simplify things we've only got one, which we'll use for any code and any data
we need. This means it'll have to be read-enabled, write-enabled, and
execute-enabled. Normally people don't do this, for security, but we won't worry
about that (don't compile any untrusted code with any compiler from this series!)
Without further ado, here's the contents of the program header:

- `01 00 00 00` Segment type 1 (this should be loaded into memory)
- `07 00 00 00` Flags = RWE (readable, writeable, and executable)
- `78 00 00 00 00 00 00 00` Offset in file = 120
- `78 00 40 00 00 00 00 00` Virtual address = 0x400078

**wait a minute, what's that?**

We just specified the *virtual address* of this segment. This is the virtual
memory address that the segment will be loaded to. Virtual memory means that
memory addresses in our program do not actually correspond to where the memory
is physically stored in RAM. There are many reasons for it, including allowing
different processes to have overlapping memory addresses, making sure that some
memory can't be read/written/executed, etc. You can read more about it
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
because the *data in the file* is loaded to address `0x400078`. The actual page
of memory that the OS will allocate for our code will start at `0x400000`. The
reason we need to start `0x78` bytes in is that Linux expects the data *in the
file* to be at the same position in the page as when it will be loaded, and it
appears at offset `0x78` in our file. Don't worry if you didn't understand all
of that.

## the code

Now we get to the actual code in our executable (well there's a bit of data here
too). We specified `0x400078` as the *entry point* of our executable, which
means that the program will start executing from there. That virtual address
corresponds to the start of the code right here:

The first thing we want to do is open our input file, `A`:

- `48 b8 74 02 40 00 00 00 00 00` `mov rax, 0x400274`
- `48 89 c7` `mov rdi, rax`
- `48 b8 00 00 00 00 00 00 00 00` `mov rax, 0`
- `48 89 c6` `mov rsi, rax`
- `48 89 c2` `mov rdx, rax`
- `48 b8 02 00 00 00 00 00 00 00` `mov rax, 2`
- `0f 05` `syscall`

These instructions execute syscall `2` with arguments `0x400274`, `0`, `0`.
If you're familiar with C code, this is `open("A", O_RDONLY, 0)`.
A syscall is the mechanism which lets software ask the kernel to do things.
[Here](https://filippo.io/linux-syscall-table/) is a nice table of syscalls you
can look through if you're interested.
Syscall #2, on Linux, is `open`. It's used to open a file. On Linux, you can
read about it by running `man 2 open`.
The first argument, `0x400274`, is a pointer to some data at the very end of
this segment (scroll down). Specifically, it holds the byte `41` (ASCII `A`),
followed by `00` (null byte). This indicates the name of the file, "A". The
second argument (`O_RDONLY`, or 0) specifies that we will be reading from this
file.  The third is only really needed when creating new files, but I've just
set it to 0, why not.

This call gives us back a *file descriptor*, used later to read from the file,
in register `rax`.

- `48 89 c5` `mov rbp, rax` Store the file descriptor for later

Now we'll open the output file

- `48 b8 76 02 40 00 00 00 00 00` `mov rax, 0x400276`
- `48 89 c7` `mov rdi, rax`
- `48 b8 41 00 00 00 00 00 00 00` `mov rax, 0x41`
- `48 89 c6` `mov rsi, rax`
- `48 b8 a4 01 00 00 00 00 00 00` `mov rax, 0o644`
- `48 89 c2` `mov rdx, rax`
- `48 b8 02 00 00 00 00 00 00 00` `mov rax, 2`
- `0f 05` `syscall`

These instructions execute the syscall `open("B", O_WRONLY|O_CREAT, 0644)`. This
is similar to our first one, but with some important differences. First, the
second argument specifies both that we are writing to a file `0x01`, and that we
want to create the file if it doesn't exist `0x40`. Secondly, the third
argument specifies the permissions that the file should be created with (`644` -
user read/write, group read). This here isn't particularly important to how the
program works.

- `48 89 ef` `mov rdi, rbp`
- `48 b8 68 02 40 00 00 00 00 00` `mov rax, 0x400268`
- `48 89 c6` `mov rsi, rax`
- `48 b8 03 00 00 00 00 00 00 00` `mov rax, 3`
- `48 89 c2` `mov rdx, rax`
- `48 b8 00 00 00 00 00 00 00 00` `mov rax, 0`
- `0f 05` `syscall`

Here we call syscall #0 (`read`) to read from a file. The arguments are:
- `fd (rdi) = rbp` read from the file descriptor we stored away earlier
- `buf (rsi) = 0x400268` output to a part of this segment I've left empty
- `count (rdx) = 3` read 3 bytes

The number of bytes *actually* read (taking into account the fact that we might
have reached the end of the file) is stored in `rax`.

Note that we read the entire file 3 bytes at a time, which is a *terrible* idea
for performance. syscalls take quite a while (3 microseconds or so, which would
make this very slow for a several-megabyte file), so modern programs tend to
read ~4KB at a time. But our programs will be small, and we don't care a lot
about performance, so it's okay.

- `48 89 c3` `mov rbx, rax`
- `48 b8 03 00 00 00 00 00 00 00` `mov rax, 3`
- `48 39 d8` `cmp rax, rbx`
- `0f 8f 37 01 00 00` `jg 0x40024d`

Together, these instructions say to jump to a different part of the code
(explained later), if we ended up reading less than 3 bytes, i.e. we reached the
end of the file. Note that rather than specifying the *address* to jump to, we
specify the *relative address* (it's relative to the address of the first byte
after the jump instruction). In other words, we're adding `0x137` to the program
counter, `rip`. This has many reasons including saving space.

- `48 b8 68 02 40 00 00 00 00 00` `mov rax, 0x400268`
- `48 89 c3` `mov rbx, rax`
- `48 8b 03` `mov rax, qword [rbx]`

This copies out 8 bytes of the data that was just read into the 64-bit register
rax. We only read 3 bytes of data from the file, but the rest will just be
zeros (because that's what we put at offset `0x268` of the file).

- `48 89 c3` `mov rbx, rax`
- `48 89 c7` `mov rdi, rax`

Here we copy away this data for later use.

- `48 b8 ff 00 00 00 00 00 00 00` `mov rax, 0xff`
- `48 21 d8` `and rax, rbx`

This grabs the first byte of data we read and stores it in `rax`. This will be
the code of the first ASCII character of the hexadecimal number in our input
file.

- `48 89 c6` `mov rsi, rax`
- `48 b8 39 00 00 00 00 00 00 00` `mov rax, 0x39 ('9')`
- `48 89 c3` `mov rax, rbx`
- `48 89 f0` `mov rax, rsi`
- `48 39 d8` `cmp rax, rbx`
- `0f 8f 1e 00 00 00` `jg 0x400173`

These instructions compare that character code against the character code for
`9`. If it's greater, then it's one of the hex digits `a` through `f`, which are
handled separately later.

- `48 b8 30 00 00 00 00 00 00 00` `mov rax, 0x30 ('0')`
- `48 f7 d8` `neg rax`
- `48 89 f3` `mov rbx, rsi`
- `48 01 d8` `add rax, rbx`

Subtract the character code for `0` from the character code we read in, to get
the *number* corresponding to the first hex digit in the pair.

- `e9 26 00 00 00` `jmp 0x400193`

Go to a different part of the program (we'll get there later).

- `00 00 00 00 00 00`

Unneeded 0 bytes I left in, to make room in case I needed it.

Now we get to the `a`-`f` handling code:

- `48 b8 a9 ff ff ff ff ff ff ff` `mov rax, -87`
- `48 89 f3` `mov rbx, rsi`
- `48 01 d8` `add rax, rbx`
- `e9 0b 00 00 00` `jmp 0x400193`
- `00 00 00 00 00 00 00 00 00 00 00` (unused)

If our character code is one of `abcdef`, we add `-87` (subtract `87`) from it,
to convert the character code to the numerical value of the digit. Here I
decided to just set `rax` to the two's complement encoding for `-87`, but you
could also use the `neg` instruction, like I did last time. <s>I just wanted to
show two different ways of doing it</s> I thought of the better way the second
time around.

Now we get to `0x400193`, the common place we jumped to from both branches.

- `48 89 c2` `mov rdx, rax`

Store away the first digit in the pair into `rdx`.

- `48 b8 ff 00 00 00 00 00 00 00` `mov rax, 0xff`
- `48 89 c3` `mov rbx, rax`
- `48 89 f8` `mov rax, rdi`
- `48 c1 e8 08` `shr rax, 8`
- `48 21 d8` `and rax, rbx`

Now we extract the second character code we read from the file.
The entire character code to number conversion is rewritten here, but slightly
differently this time because I came up with some new ideas.

- `48 93` `xchg rax, rbx`
- `48 b8 39 00 00 00 00 00 00 00` `mov rax, 0x39 ('9')`
- `48 93` `xchg rax, rbx`
- `48 39 d8` `cmp rax, rbx`
- `0f 8f 1f 00 00 00` `jg 0x4001e3 ('a'-'f' handling code)`
- `48 89 c3` `mov rbx, rax`
- `48 b8 d0 ff ff ff ff ff ff ff` `mov rax, -48`
- `48 01 d8` `add rax, rbx`
- `e9 2a 00 00 00` `jmp 0x400203`
- `00 00 00 00 00 00 00 00 00 00` (unused)

('a'-'f' handling)
- `48 89 c3` `mov rbx, rax`
- `48 b8 a9 ff ff ff ff ff ff` `mov rax, -87`
- `48 01 d8` `add rax, rbx`
- `e9 0c 00 00` `jmp 0x400203`
- `00 00 00 00 00 00 00 00 00 00 00 00 00` (unused)

(common code)
- `48 89 c7` `mov rdi, rax`

Okay now we've read the first hex digit into `rdx`, and the second into `rdi`.

- `48 89 d0` `mov rax, rdx`
- `48 c1 e0 04` `shl rax, 4`
- `48 89 fb` `mov rbx, rsi`
- `48 09 d8` `or rax, rbx`

Okay, now we have the full hexadecimal number in `rax`!

- `48 93` `xchg rax, rbx`
- `48 b8 68 02 40 00 00 00 00 00` `mov rax, 0x400268`
- `48 93` `xchg rax, rbx`
- `48 89 03` `mov qword [rbx], rax`

This stores the byte we want to write to the file at address `0x400268`. This is
the same address we used to read in the input text; again, it's just part of
this segment I've left blank.

- `48 89 de` `mov rsi, rbx`
- `48 b8 04 00 00 00 00 00 00 00` `mov rax, 4`
- `48 89 c7` `mov rdi, rax`
- `48 b8 01 00 00 00 00 00 00 00` `mov rax, 1`
- `48 89 c2` `mov rdx, rax`
- `0f 05` `syscall`

Here we call syscall #1, `write`, with arguments:

- `fd = 4` we could have stored away the file descriptor we got before for the
output file, like we did with the input file, but I was out of easy-to-use
registers! Instead, we can use the fact that Linux assigns file descriptors
sequentially starting from 3 (0, 1, and 2 are standard input, output, and
error), so we know our output file, the second file we opened, will have
descriptor 4.
- `buf = 0x400268` where we put our data
- `count = 1` write 1 byte

- `e9 8f fe ff ff` `jmp 0x4000d7`
- `00 00 00 00 00` (unused)

Now we go back to read in the next pair of digits! Finally...

- `48 b8 3c 00 00 00 00 00 00 00` `mov rax, 0x3c`
- `0f 05` `syscall`

This is where we conditionally jumped to way back when we determined if we
reached the end of the file. This just calls syscall #60, `exit`, to exit our
program nicely. We didn't specify the exit code, but that's okay for our
purposes.
And we could close the files (syscall #3), to tell Linux we're done with them,
but we don't need to. It'll close all our open file descriptors when our program
exits.


- `00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00` Unused bytes (I wasn't
sure exactly how long the program would be)
- `00 00 00 00 00 00 00 00` This is where we read/wrote the file data!
- `41 00` Input file name, `"A"`
- `42 00` Output file name, `"B"`

That's quite a lot to take in for such a simple program, but here we are! We now
have something that will let us write individual bytes with an ordinary text
editor and get them translated into a binary file.
