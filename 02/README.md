# [bootstrap](../README.md) stage 02

The compiler for this stage is in the file `in01`, an input for our [previous compiler](../01/README.md).
So if you run `../01/out00`, you'll get the file `out01`, which is
this stage's compiler.
The specifics of how this compiler works are in the comments in `in01`, but here I'll
give an overview.
Let's take a look at `in02`, an example input file for this compiler:
```
jm
:-co   jump to code
::hw  start of hello world
'H
'e
'l
'l
'o
',
' 
'w
'o
'r
'l
'd
'!
\n
::he  end of hello world



::co  start of code
// calculate the length of the hello world string
// by subtracting hw from he.
im
--he
BA
im
--hw
nA
+B
DA   put length in rdx
// okay now write it
im
##1.
JA    set rdi to 1 (stdout)
im
--hw
IA    set rsi to a pointer to "Hello, world!\n"
im
##1.  write
sy
im
##0.  exit code 0
JA
im
##3c. exit = syscall 0x3c
sy
```

We can compile it by running `./out01`. This will produce
the executable `out02`, which you can run. It prints
`Hello, world!`.

In this language,
commands are separated by newlines instead of semicolons.
Each line begins with a 2-character command.
All of the commands from the previous compiler are here,
plus six new ones:

- `::` marks a *label*
- `--` outputs a label's (absolute) address
- `:-` outputs a label's relative address
- `##` outputs a number
- `~~` outputs 255 zeros
- `//` is for comments
- `\n\n` does nothing (used for spacing)

Also, the conditional jump instructions now have a `cmp rax, rbx`
built into them.

## labels

Labels are the most important new feature of this language.
A line like
```
::xy
```
associates the name `xy` with the address of the next byte of the program.
In the example program, `hw` is associated with `0x40007d`, 
which is the virtual memory address of the `Hello, world!` data.
We can then use
```
--xy
```
to output that address, and
```
:-xy
```
to output it relative to the current address.
So now instead of computing how far to jump, we can just jump to a label, e.g.
```
jm
:-xy  (use the relative address, because jumps are relative in x86-64)
```
And instead of figuring out the address of a piece of data, we can just use its label:
```
im
--xy
// rax now points to the data at the label "::xy"
```

This also lets us compute the length of the hello world string automatically!
By taking the address of the end of the string (`he`) and subtracting the
start (`hw`), we get the length in bytes.
So you can try adding more characters to the hello world message, and it'll just work.

All labels must be two ASCII characters. The address of each label is stored
as a 32-bit number in the "label table". This is sort of like the command table—the
index of the label `xy` is `128 * x + y`. Specifically, the entry for `xy` is at
`0x420000 + 4 * (128 * x + y)`, since the label table starts at `0x420000`
and each entry is 4 bytes.
When we encounter `::xy`, we get the current position in the output file
(using `lseek`), add the address of the start of the file (`0x400000`), 
and store that in the label table.
When we encounter `:-xy` or `--xy`, we look up `xy` in the label table,
and write the address (subtracting the current address for `:-`) to the output file.

## two passes?

This compiler actually needs to read through the source code,
and output an executable, twice.
This is because a label may be defined *after* it is used, e.g.:
```
jm
:-aa   jump forward
...
::aa   this is where we're jumping to
...
```
In the first pass, the `:-aa` will
treat `aa` as having an address of 0. Then when
we get to `::aa`, the address in the label table will be corrected.
At the end of the first pass, we seek back to the start 
of the input and output files,
and run the exact same code for the second pass.
But this time, the correct address of `aa` is used, namely the
one we calculated in the first pass.


## other features

Now instead of writing out each of the 8 bytes making up a number,
we can just write it in hexadecimal, e.g. `##1c4.` for `c4 01 00 00 00 00 00 00`.
This is especially nice because we don't need to write numbers backwards
for little-endianness anymore!
Numbers cannot appear at the end of a line (this made
the compiler simpler to write), so I'm adding a `.` at the end of
each one to avoid making that mistake.

Anything after a command is treated as a comment;
additionally `//` can be used for comments on their own lines.
I decided to implement this as simply as possible:
I just added the command `//` to the command table, which outputs the byte `0x90`—this
means ["do nothing"](https://en.wikipedia.org/wiki/No-op)
in x86-64.
Note that the following code will not work as expected:
```
im
// load the value 0x333 into rax
##333.
```
since `0x90` gets inserted between the "load immediate" instruction code and the immediate.
`\n\n` works identically, and lets us space out code a bit. But be careful:
the number of blank lines must be a multiple of 3!

In the middle of the label table, you'll find a mysterious `ff` byte. This is at the position for
the command `~~` (the end of the command table overlaps with the start of the label table).
This command is just 255 bytes of zeros. If you defined a label whose position in the label
table overlaps with these zeros, you'd screw up the command. But fortunately, this will only happen
if you include `\r` or a non-printing character in your label names.
The `~~` command makes it easier to create big buffers to put data in (like our label table from this compiler).

## limitations

Many of the limitations of our previous compilers apply to this one. Also,
if you use a label without defining it, it uses address 0, rather than outputting
an error message. This could be fixed: if the value in the label table is 0 and we are
on the second pass, output an error message. Also, duplicate labels aren't detected.

But thanks to labels, at least we won't have to calculate
any jump offsets manually anymore. With that, let's move on to [stage 03](../03/README.md).
