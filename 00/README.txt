--- stage 00 ---

This directory contains the file 'hexcompile', a handwritten executable.
It takes an input file A containing space/newline/[any character]-separated
hexadecimal numbers and outputs them as bytes to the file B. On 64-bit Linux,
try running ./hexcompile from this directory (I've already provided an A file),
and you will get a file named B containing the text "Hello, world!".
I made this program so that you can use your favorite text editor to write
executables by hand (which have bytes outside of ASCII/UTF-8).
I wrote it with a program called hexedit, which can be found on most Linux
distributions. Only 64-bit Linux is supported, because each OS/architecture
combination would need its own separate executable. The executable is 632 bytes
long, and you could definitely make it smaller if you wanted to. Let's take a
look at what's inside (see hexdump -C hexcompile):
7f 45 4c 46 02 01 01 00  00 00 00 00 00 00 00 00
02 00 3e 00 01 00 00 00  78 00 40 00 00 00 00 00
40 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
00 00 00 00 40 00 38 00  01 00 00 00 00 00 00 00
01 00 00 00 07 00 00 00  78 00 00 00 00 00 00 00
78 00 40 00 00 00 00 00  00 00 00 00 00 00 00 00
00 02 00 00 00 00 00 00  00 02 00 00 00 00 00 00
00 10 00 00 00 00 00 00  48 b8 74 02 40 00 00 00
00 00 48 89 c7 48 b8 00  00 00 00 00 00 00 00 48
89 c6 48 89 c2 48 b8 02  00 00 00 00 00 00 00 0f
05 48 89 c5 48 b8 76 02  40 00 00 00 00 00 48 89
c7 48 b8 41 00 00 00 00  00 00 00 48 89 c6 48 b8
a4 01 00 00 00 00 00 00  48 89 c2 48 b8 02 00 00
00 00 00 00 00 0f 05 48  89 c1 48 89 ef 48 b8 68
02 40 00 00 00 00 00 48  89 c6 48 b8 03 00 00 00
00 00 00 00 48 89 c2 48  b8 00 00 00 00 00 00 00
00 0f 05 48 89 c3 48 b8  03 00 00 00 00 00 00 00
48 39 d8 0f 8f 37 01 00  00 48 b8 68 02 40 00 00
00 00 00 48 89 c3 48 8b  03 48 89 c3 48 89 c7 48
b8 ff 00 00 00 00 00 00  00 48 21 d8 48 89 c6 48
b8 39 00 00 00 00 00 00  00 48 89 c3 48 89 f0 48
39 d8 0f 8f 1e 00 00 00  48 b8 30 00 00 00 00 00
00 00 48 f7 d8 48 89 f3  48 01 d8 e9 26 00 00 00
00 00 00 00 00 00 48 b8  a9 ff ff ff ff ff ff ff
48 89 f3 48 01 d8 e9 0b  00 00 00 00 00 00 00 00
00 00 00 00 00 00 48 89  c2 48 b8 ff 00 00 00 00
00 00 00 48 89 c3 48 89  f8 48 c1 e8 08 48 21 d8
48 93 48 b8 39 00 00 00  00 00 00 00 48 93 48 39
d8 0f 8f 1f 00 00 00 48  89 c3 48 b8 d0 ff ff ff
ff ff ff ff 48 01 d8 e9  2a 00 00 00 00 00 00 00
00 00 00 00 00 00 48 89  c3 48 b8 a9 ff ff ff ff
ff ff 48 01 d8 e9 0c 00  00 00 00 00 00 00 00 00
00 00 00 00 00 00 48 89  c7 48 89 d0 48 c1 e0 04
48 89 fb 48 09 d8 48 93  48 b8 68 02 40 00 00 00
00 00 48 93 48 89 03 48  89 de 48 b8 04 00 00 00
00 00 00 00 48 89 c7 48  b8 01 00 00 00 00 00 00
00 48 89 c2 0f 05 e9 8f  fe ff ff 00 00 00 00 00
48 b8 3c 00 00 00 00 00  00 00 0f 05 00 00 00 00
00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
00 00 00 00 41 00 42 00

Okay, that doesn't tell us much, I'll annotate it below. You might notice that
all the numbers are backwards, e.g. 3e 00 for the number 0x003e (62 decimal).
This is because almost all modern architectures (including x86-64) are
little-endian, meaning that the *least significant byte* goes first, and the
most significant byte goes last. There are various reasons why this is easier to
deal with, which I won't explain here.

-- ELF header --
This header has a bunch of metadata about the executable.

7f 45 4c 46 - Special identifier saying that this is an ELF file (ELF is the
format of almost all Linux executables)
02 - 64-bit
01 - Little-endian
01 - ELF version 1 (there is no version 2 yet)
00 00 00 00 00 00 00 00 00 - Reserved (not important yet, but may be in a later
version of ELF)
02 00 - This is an executable file (not a dynamic library/etc)
3e 00 - Architecture x86-64
01 00 00 00 - Version 1 of ELF (minor version or something)
78 00 40 00 00 00 00 00 - **Entry point of the executable** = 0x400078 (explained later)
40 00 00 00 00 00 00 00 - Program header table offset in bytes from start of file (see below)
00 00 00 00 00 00 00 00 - Section header table offset (we're not using sections)
00 00 00 00 - Flags (not important)
40 00 - The size of this header, in bytes = 64
38 00 - Size of the program header (see below) = 56
01 00 - Number of program headers = 1
00 00 - Size of each section header (unused)
00 00 - Number of section headers (unused)
00 00 - Index of special .shstrtab section (unused)

-- Program header --
The program header describes a segment of data that is loaded into memory when
the program starts. Normally, you would have more than one of these, one for
code, one for read-only data, and one for read-write data, perhaps, but to
simplify things we've only got one, which we'll use for any code and any data
we need. This means it'll have to be read-enabled, write-enabled, *and*
execute-enabled. Normally people don't do this, for security, but we won't worry
about that (don't compile any untrusted code with any compiler from this series!)
Without further ado, here's the contents of the program header:

01 00 00 00 - Segment type 1 (this should be loaded into memory)
07 00 00 00 - Flags = RWE (readable, writeable, and executable)
78 00 00 00 00 00 00 00 - Offset in file = 120
78 00 40 00 00 00 00 00 - Virtual address = 0x400078
- Wait a minute, what's that? -
We just specified the *virtual address* of this segment. This is the virtual
memory address that the segment will be loaded to. Virtual memory means that
memory addresses in our program do not actually correspond to where the memory
is physically stored in RAM. There are many reasons for it, including allowing
different processes to have overlapping memory addresses, making sure that some
memory can't be read/written/executed, etc. You can read more about it
elsewhere.
00 00 00 00 00 00 00 00 - Physical address (not applicable)
00 02 00 00 00 00 00 00 - Size of this segment in the executable file = 512
bytes
00 02 00 00 00 00 00 00 - Size of this segment when loaded into memory = also
512 bytes
00 10 00 00 00 00 00 00 - Segment alignment = 4096 bytes
48 b8 74 02 40 00 00 00
00 00 48 89 c7 48 b8 00  00 00 00 00 00 00 00 48
89 c6 48 89 c2 48 b8 02  00 00 00 00 00 00 00 0f
05 48 89 c5 48 b8 76 02  40 00 00 00 00 00 48 89
c7 48 b8 41 00 00 00 00  00 00 00 48 89 c6 48 b8
a4 01 00 00 00 00 00 00  48 89 c2 48 b8 02 00 00
00 00 00 00 00 0f 05 48  89 c1 48 89 ef 48 b8 68
02 40 00 00 00 00 00 48  89 c6 48 b8 03 00 00 00
00 00 00 00 48 89 c2 48  b8 00 00 00 00 00 00 00
00 0f 05 48 89 c3 48 b8  03 00 00 00 00 00 00 00
48 39 d8 0f 8f 37 01 00  00 48 b8 68 02 40 00 00
00 00 00 48 89 c3 48 8b  03 48 89 c3 48 89 c7 48
b8 ff 00 00 00 00 00 00  00 48 21 d8 48 89 c6 48
b8 39 00 00 00 00 00 00  00 48 89 c3 48 89 f0 48
39 d8 0f 8f 1e 00 00 00  48 b8 30 00 00 00 00 00
00 00 48 f7 d8 48 89 f3  48 01 d8 e9 26 00 00 00
00 00 00 00 00 00 48 b8  a9 ff ff ff ff ff ff ff
48 89 f3 48 01 d8 e9 0b  00 00 00 00 00 00 00 00
00 00 00 00 00 00 48 89  c2 48 b8 ff 00 00 00 00
00 00 00 48 89 c3 48 89  f8 48 c1 e8 08 48 21 d8
48 93 48 b8 39 00 00 00  00 00 00 00 48 93 48 39
d8 0f 8f 1f 00 00 00 48  89 c3 48 b8 d0 ff ff ff
ff ff ff ff 48 01 d8 e9  2a 00 00 00 00 00 00 00
00 00 00 00 00 00 48 89  c3 48 b8 a9 ff ff ff ff
ff ff 48 01 d8 e9 0c 00  00 00 00 00 00 00 00 00
00 00 00 00 00 00 48 89  c7 48 89 d0 48 c1 e0 04
48 89 fb 48 09 d8 48 93  48 b8 68 02 40 00 00 00
00 00 48 93 48 89 03 48  89 de 48 b8 04 00 00 00
00 00 00 00 48 89 c7 48  b8 01 00 00 00 00 00 00
00 48 89 c2 0f 05 e9 8f  fe ff ff 00 00 00 00 00
48 b8 3c 00 00 00 00 00  00 00 0f 05 00 00 00 00
00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
00 00 00 00 41 00 42 00
