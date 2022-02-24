# [bootstrap](../README.md) stage 01

The code for the compiler for this stage is in the file `in00`. And yes, that's
an input to our [previous program](../00/README.html), `hexcompile`, from stage 00! To compile it,
run `../00/hexcompile` from this directory. You will get a file, `out00`. That
is the executable for this stage's compiler. Run it (it'll read from the file
`in01` I've provided) and you'll get a file `out01`. That executable will print
`Hello, world!` when run. Let's take a look at the input we're providing to the
stage 01 compiler, `in01`:

```
|| ELF Header
;im;01;00;00;00;00;00;00;00 file descriptor for stdout
;JA
;im;bc;00;40;00;00;00;00;00 address of string "Hello, world!\n"
;IA
;im;0e;00;00;00;00;00;00;00 number of bytes to output
;DA
;im;01;00;00;00;00;00;00;00 syscall #1 (write)
;sy
;zA
;DA exit code 0
;im;3c;00;00;00;00;00;00;00 syscall #60 (exit)
;sy
;'H;'e;'l;'l;'o;',;' ;'w;'o;'r;'l;'d;'!;\n the string we're printing
;
```

Look at that! There are even comments! Much nicer than just hexadecimal digit pairs.

## end result

Our 01 compiler will take a very basic "assembly" language, and output an
executable. The input file consists of a bunch of two-character commands
separated by semicolons. Any text after the command and before the semicolon is
ignored (that's how we get comments), and there has to be a terminating
semicolon.

For example, the `sy` command outputs a syscall instruction and the
`zA` command sets `rax` to 0. You can see
`commands.txt` for a full list.

`||` is a very important command. It outputs an ELF header for our executable.
Rather than compute the correct size of the file, it just sets the "file size"
and "memory size" members of the program header to `0x80000` (enough for a 512KB
executable). As it turns out, Linux won't mind if the program header lies about
how much data is in the file.

If an unrecognized instruction is encountered, this compiler will
actually print out an error message and exit, rather than continuing as if
nothing happened! Try adding `xx;` to the end of the file `in01`, and running
`./out00`. You should get the error message:

```
xx not recognized.
```

Pretty cool, huh?
Anyways let's see how this compiler actually works.

## compiler source

Writing in our stage 00 language is much nicer than editing an
executable, because it's easier to move things around, and also, we can separate
our program into lines! Let's take a look at the start:

```
7f 45 4c 46
02
01
01
00 00 00 00 00 00 00 00 00
02 00
3e 00
01 00 00 00
a8 00 40 00 00 00 00 00
40 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00
40 00
38 00
01 00
00 00
00 00
00 00
01 00 00 00
07 00 00 00
78 00 00 00 00 00 00 00
78 00 40 00 00 00 00 00
00 00 00 00 00 00 00 00
00 10 02 00 00 00 00 00
00 10 02 00 00 00 00 00
00 10 00 00 00 00 00 00
```

This is the ELF header and program header. It's just like our last one, but with
a couple of differences. First, our entry point is at offset 0xa8 instead of 0x78.
I decided to put the data before the code this time (it made it a bit
easier to work with), so we start a little bit later than the first byte in our
segment.  Second and more importantly, rather than 512 bytes, our segment is
0x21000 = 135168 bytes long! That's because we're storing a table of all the
commands our compiler supports. This table has one 8-byte entry for each
pair of ASCII characters. There are 128 ASCII characters, so that means it's
`128 * 128 * 8 = 131072` bytes long. This large source file means that compiling our
stage 01 compiler isn't instantaneous (remember how I said reading 3 bytes at a
time would be slow?). On my system, it takes 0.13 seconds to run
`../00/hexcompile`.


- `69 6e 30 31 00` `"in01"`
- `6f 75 74 30 31 00` `"out01"`
- `00 00 20 6e 6f 74 20 72 65 63 6f 67 6e 69 7a 65 64 2e 0a` `"\0\0 not
recognized."`
- `00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00` (unused)

Here's the data for our program. As you can see from my annotations, we have the
input and output file names, as well as the error message. The command part of the
error message is left blank for now (we'll fill it in when the code is actually
run).

Okay, now we get to the actual code. The entry point is right here:

- `48 b8 78 00 40 00 00 00 00 00` `mov rax, 0x400078 ("in01")`
- `48 89 c7` `mov rdi, rax`
- `31 c0` `mov rax, 0`
- `48 89 c6` `mov rsi, rax`
- `48 b8 02 00 00 00 00 00 00 00` `mov rax, 2`
- `0f 05` `syscall`

This is an `open` syscall, just like from stage 00. We're opening our input file.

- `48 b8 7d 00 40 00 00 00 00 00` `mov rax, 0x40007d ("out01")`
- `48 89 c7` `mov rdi, rax`
- `48 b8 41 02 00 00 00 00 00 00` `mov rax, 0x241`
- `48 89 c6` `mov rsi, rax`
- `48 b8 ed 01 00 00 00 00 00 00` `mov rax, 0o755`
- `48 89 c2` `mov rdx, rax`
- `48 b8 02 00 00 00 00 00 00 00` `mov rax, 2`
- `0f 05` `syscall`

This opens our output file, just like last time.

- `48 b8 03 00 00 00 00 00 00 00` `mov rax, 3 (input fd)`
- `48 89 c7` `mov rdi, rax`
- `48 b8 83 00 40 00 00 00 00 00` `mov rax, 0x400083`
- `48 89 c6` `mov rsi, rax`
- `48 b8 02 00 00 00 00 00 00 00` `mov rax, 2`
- `48 89 c2` `mov rdx, rax`
- `31 c0` `mov rax, 0`
- `0f 05` `syscall`

Here we read two bytes from our input file into memory address `0x400083`. Note
that this corresponds to those two blank bytes at the start of our error
message.

- `48 89 c3` `mov rbx, rax`
- `48 b8 01 00 00 00 00 00 00 00` `mov rax, 1`
- `48 39 d8` `cmp rax, rbx`
- `0f 8c 17 00 00 00` `jl +0x17`

If we actually read two bytes, jump forward past this bit of code right here:

- `31 c0` `mov rax, 0`
- `48 89 c7` `mov rdi, rax`
- `48 b8 3c 00 00 00 00 00 00 00` `mov rax, 0x3c (exit)`
- `0f 05` `syscall`
- `00 00 00 00 00 00` (unused)

This code is only run when the end of the file is reached. It just exits the
program with exit code 0 (successful).

- `48 b8 83 00 40 00 00 00 00 00` `mov rax, 0x400083`
- `48 89 c3` `mov rbx, rax`
- `31 c0` `mov rax, 0`
- `8a 03` `mov al, byte [rbx]`
- `48 c1 e0 07` `shl rax, 7`
- `48 89 c7` `mov rdi, rax`
- `48 b8 84 00 40 00 00 00 00 00` `mov rax, 0x400084`
- `48 89 c3` `mov rbx, rax`
- `31 c0` `mov rax, 0`
- `8a 03` `mov al, byte [rbx]`
- `48 89 fb` `mov rbx, rdi`
- `48 01 d8` `add rax, rbx`

This here looks at the two bytes we read in (we'll call them `b1` and `b2`) and
computes `b1 * 128 + b2` (more specifically `(b1 << 7) + b2`). This is the corresponding index
in our command table.

- `48 c1 e0 03` `shl rax, 3`
- `48 89 c3` `mov rbx, rax`
- `48 b8 00 10 40 00 00 00 00 00` `mov rax, 0x401000`
- `48 01 d8` `add rax, rbx`
- `48 89 c5` `mov rbp, rax`

Now we compute the address of the entry in the command table. Each entry is 8
bytes long, so we shift the index left by 3 (multiply by 8), and then add
`0x401000`, the address of the start of the table. We store away the computed
address in `rbp` for later use.

- `48 89 c3` `mov rbx, rax`
- `31 c0` `mov rax, 0`
- `8a 03` `mov al, byte [rbx]`
- `48 89 c3` `mov rbx, rax`
- `31 c0` `mov rax, 0`
- `48 39 d8` `cmp rax, rbx`
- `0f 85 5a 00 00 00` `jne +0x5a`

The format of each command table entry is the length of the data to output,
stored as one byte, followed by the data. So the entry for `BA (mov rbx, rax)`
is `03 48 89 c3`. We set the length to 0 for unused entries.

So this code checks if the entry for this command starts with a zero byte. If it
does, that means the two characters we read in don't actually correspond to a
real command. If that's the case, this next bit of code is executed (otherwise
it's skipped over):

- `48 b8 02 00 00 00 00 00 00 00` `mov rax, 2 (stderr)`
- `48 89 c7` `mov rdi, rax`
- `48 b8 83 00 40 00 00 00 00 00` `mov rax, 0x400083 ("XX not recognized")`
- `48 89 c6` `mov rsi, rax`
- `48 b8 13 00 00 00 00 00 00 00` `mov rax, 13 (length)`
- `48 89 c2` `mov rdx, rax`
- `48 b8 01 00 00 00 00 00 00 00` `mov rax, 1 (write)`
- `0f 05` `syscall`
- `48 b8 01 00 00 00 00 00 00 00` `mov rax, 1 (exit code)`
- `48 89 c7` `mov rdi, rax`
- `48 b8 3c 00 00 00 00 00 00 00` `mov rax, 60 (exit)`
- `0f 05` `syscall`
- `00 00 00 00 00 00 00 00 00 00 00 00 00 00` (unused)

This prints our error message, now filled in with the specific unrecognized
instruction, to standard error, then exits with code 1, to indicate failure.

- `48 89 eb` `mov rbx, rax`
- `31 c0` `mov rax, 0`
- `8a 03` `mov al, byte [rbx]`
- `48 89 c2` `mov rdx, rax`

This puts the length of the data for this command into `rdx` (the `length`
argument to the `write` syscall is passed in `rdx`).

- `48 b8 04 00 00 00 00 00 00 00` `mov rax, 4`
- `48 89 c7` `mov rdi, rax`
- `48 89 eb` `mov rbx, rbp`
- `48 b8 01 00 00 00 00 00 00 00` `mov rax, 1`
- `48 01 d8` `add rax, rbx`
- `48 89 c6` `mov rax, rsi`
- `48 b8 01 00 00 00 00 00 00 00` `mov rax, 1`
- `0f 05` `syscall`

Now we write the actual data for this command! Note that we add 1 to the address
we computed earlier, to skip over the byte indicating how long the command is.

- `48 b8 03 00 00 00 00 00 00 00` `mov rax, 3 (input fd)`
- `48 89 c7` `mov rdi, rax`
- `48 b8 83 00 40 00 00 00 00 00` `mov rax, 0x400083`
- `48 89 c6` `mov rsi, rax`
- `48 b8 01 00 00 00 00 00 00 00` `mov rax, 1 (length)`
- `48 89 c2` `mov rdx, rax`
- `31 c0` `mov rax, 0 (read)`
- `0f 05` `syscall`
- `48 b8 83 00 40 00 00 00 00 00` `mov rax, 0x400083`
- `48 89 c3` `mov rbx, rax`
- `31 c0` `mov rax, 0`
- `8a 03` `mov al, byte [rbx]`
- `48 89 c3` `mov rbx, rax`
- `48 b8 3b 00 00 00 00 00 00 00` `mov rax, 0x3b (';')`
- `48 39 d8` `cmp rax, rbx`
- `0f 85 ae ff ff ff` `jne -0x52`
- `e9 66 fe ff ff` `jmp -0x19a`

Here we read one byte at a time from the input file, and if it's `;`, we jump
all the way back to read the next command. Otherwise, we keep looping. This
skips over any comments/whitespace we might have between a command and the
following command.

And that's all the *code* for this compiler. Next comes the command table.

First, there's a whole bunch of unused 0s. Then there's the line

- `cc cc cc cc cc cc cc cc`

This is only here for decoration, to mark the start of the command table (at
address `0x401000`). It appears on line 272, so we can compute the line number
to put each command on as `c1 * 128 + c2 + 272`, where `c1` and `c2` are the
ASCII character codes used for the command. So, `sy` (s = ASCII 115, y = ASCII
121) would be put on line `115 * 128 + 121 + 272 = 15113`. Sure enough, scroll
down to line 15113, and you'll see:

- `02 0f 05 00 00 00 00 00` (2 bytes long, data `0f 05`)

Which is the encoding of the `syscall` instruction.

You can look through the rest of the table, if you want. But let's look at the
very end:

```
78
7f 45 4c 46
02
01
01
00 00 00 00 00 00 00 00 00
02 00
3e 00
01 00 00 00
78 00 40 00 00 00 00 00
40 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00
40 00
38 00
01 00
00 00
00 00
00 00
01 00 00 00
07 00 00 00
00 00 00 00 00 00 00 00
00 00 40 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 08 00 00 00 00 00
00 00 08 00 00 00 00 00
00 10 00 00 00 00 00 00
```

This is at the position for `||`, and it contains an ELF header. One thing you
might notice is that we decided that each entry is 8 bytes long, but this one is
0x79 = 121 bytes long! It's okay, our code doesn't check if we use more
than 8 bytes of data, but it means that the entries for certain
commands, e.g. `}\n` will land right in the middle of the data for the ELF
header. But by a lucky coincidence, all those entries actually land on 0 bytes,
so they'll just be treated as unrecognized (as they should be).

## limitations

Like our last program, this one will be slow for large files. Again, that isn't
much of a problem for us. Also, if you forget a `;` at the end of a file, it'll
loop infinitely rather than printing a nice error message. I could have
fixed this, but frankly I've had enough of writing code in hexadecimal. So let's
move on to [stage 02](../02/README.md),
now that we have a nicer language on our hands. From now
on, since we have comments, I'm gonna do most of the explaining in the source file
itself, rather than the README. But there'll still be some stuff there each
time.
