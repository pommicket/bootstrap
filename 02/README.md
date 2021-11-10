# stage 02

The compiler for this stage is in the file `in01`, an input for our previous compiler.
The specifics of how this compiler works are in the comments in that file, but here I'll
give an overview.
Let's take a look at `in02`, an example input file for this compiler:
```
jm
:-co   jump to code
::hw
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
//
// now we'll calculate the length of the hello world string
// by subtracting hw from he.
//
im
--he
BA
im
--hw
nA
+B
DA   put length in rdx
// okay now we can write it
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

You can try adding more characters to the hello world message, and it'll just work;
the length of the text is computed automatically!

This time, commands are separated by newlines instead of semicolons.
Each line begins with a 2-character command identifier. There are some special identifiers though:

- `::` marks a *label*
- `--` outputs a label's (absolute) address
- `:-` outputs a label's relative address
- `##` outputs a number

All other commands work like they did in the previous compiler—if you scroll down in the
`in01` source file, you'll see the full command table.

## labels

Labels are the most important new feature of this language.

## two passes?

## other features

Now instead of writing out each of the 8 bytes making up a number,
we can just write it in hexadecimal (e.g. `##3c.` for `3c 00 00 00 00 00 00 00`),
and the compiler will automatically
extend it to 8 bytes.
This is especially nice because we don't need to write numbers backwards
for little-endianness anymore!
Numbers cannot appear at the end of a line (this was
to make the compiler simpler to write), so I'm adding a `.` at the end of
each one to avoid making that mistake.

Anything after a command is treated as a comment;
additionally `//` can be used for comments on their own lines.
I decided to implement them as simply as possible:
I just added the command `//` to the command table, which outputs the byte `0x90`—this
means "do nothing" (`nop`) in x86-64.
Note that this means that the following code will not work as expected:
```
im
// load the value 0x333 into rax
##333.
```
since `0x90` gets inserted between the "load immediate" instruction code, and the immediate.

## limitations

Many of the limitations of our previous compilers apply to this one. Also,
if you use a label without defining it, it uses address 0, rather than outputting
an error message. This could be fixed: if the value in the label table is 0, and if we are
on the second pass, output an error message. This compiler was already tedious enough
to implement, though! 
But thanks to labels, for future compilers at least we won't have to calculate
any jump offsets manually.
