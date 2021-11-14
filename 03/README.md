# stage 03
The code for this compiler (the file `in02`, an input for our [stage 02 compiler](../02/README.md))
is 2700 lines—quite a bit larger than the previous ones. And as we'll see, it's a lot more powerful too.
To compile it, run `../02/out01` from this directory.
Let's take a look at `in03`, the example program I've written for it:
```
B=:hello_world
call :puts
; exit code 0
J=d0
syscall x3c

:hello_world
str Hello, world!
xa
x0

; output null-terminated string in rbx
:puts
	R=B
	call :strlen
	D=A
	I=R
	J=d1
	syscall d1
	return

; calculate length of string in rbx
:strlen
	; keep pointer to start of string
	D=B
	I=B
	:strlen_loop
	C=1I
	?C=0:strlen_loop_end
	I+=d1
	!:strlen_loop
	:strlen_loop_end
	I-=D
	A=I	
	return
```
This language looks a lot nicer than the previous one. No more obscure two-letter label names
and commands! Furthermore, try changing `:strlen_loop` on line 31
to a typo like `:strlen_lop`. You should get:
```
Bad label 001f
```
Not only do we get an error message, we also get the line number
of the error! It's in hexadecimal, unfortunately, but that's
better than nothing.

I spent a while on this compiler (perhaps I went a bit overboard
on the features), because for the 02 language
was the first that was actually pleasant to use!
It's much less sophisticated than even most assembly languages,
but being able to use labels without having to worry about filling
in the offsets later made it way nicer to use than the previous
languages.

In addition to `in03`, this directory also has `ex03`,
which gives examples of all of the instructions supported by this compiler.

Seeing as this is a relatively large compiler,
here is an overview of how it works:

## functions

Thanks to labels, we can actually use functions in this compiler, without
it being a complete nightmare. Functions are called like this:
```
im
--fu
cl    (this would call the function ::fu)
```
and at the end of each function, we get `re`, which returns from the function.
I've used the convention of storing return values in `rax` and
passing the argument to a unary function in `rbx`.

This compiler ended up having a lot of functions, some of them used in all sorts
of different places.

## execution

Just as with the 02 compiler, we need two passes:
the first one
computes the address of each label,
and the second one uses the correct addresses to
write the executable.

Each pass is a loop, which starts by incrementing
the line number (`::L#`). Then we read in a line
from the source file, `in03`. This is done one character
at a time, until a newline is reached. The line is stored
in the buffer `::LI`. In the remainder of the program we
(mostly) use the fact that the line is newline-terminated,
rather than keeping track of how long it is.

Once the line is read in, a bunch of tests are performed on it.
We start by looking at the first character: if it's a `;`,
the line is a comment; if it's a `!`, it's an unconditional jump; etc.
Failing that, we look at the second character, to see if it's
`=`, `+=`, `-=`, etc. If it doesn't match any of them, we use
the `::s=` (string equals) function, which conveniently lets you
set the terminator. We check if the line is equal to `"syscall"`
up to a terminator of `'&nbsp;'` to check if it's a syscall, for example.

## `+=`, et al.

We can emit the correct instruction for `D+=C` with:

- `mov rbx, rdx`
- `mov rax, rcx`
- `add rax, rbx`
- `mov rdx, rax`

A similar pattern can be used for `-=`, `&=`, etc.
This made it pretty easy to write the implementation of all of these:
there's one function for setting `rbx` to the first operand (`::B1`),
another for setting `rax` to the second operand (`::A2`), and another for
setting the first operand to `rax` (`::1A`). The implementations of
`+=`/`-=`/etc. just call those three functions, with a bit of stuff in between
to perform the corresponding operation.
A similar approach also works for loading/storing values in memory.

## label list

Instead of a label table, we now have a "label list" (or array
if you prefer) at `::LB`.
A pointer to the current end of the list is stored at `::L$`.
Each entry is the name of the label, including the `:`, then a newline,
then the 4-byte address.
`::ll` is used to look up labels. If it's the first pass,
`::ll` just returns 0. Otherwise, it looks up the label by
comparing it to each entry using `s=` with a terminator of `'\n'`.
If no label matches, we get an error.

## alignment
A lot of data used in this program is
[not correctly aligned](https://en.wikipedia.org/wiki/Bus_error#Unaligned_access)—e.g.
8-byte values are not always stored at an address that is a multiple of 8.
This would be a problem on some processors, but x86-64 can handle it.
It's still not a good idea in practice—reading unaligned memory
is much slower. But we're not really concerned about performance here,
and it would be a bit finnicky to align everything correctly.
However, I have introduced `align` into this language,
which you can put before a label to ensure that its address is aligned
to 8 bytes.

## errors

Errors are handled in functions beginning with `!`, e.g. `::!n` for "bad number".
Each of these ends up calling `::er`. `::er` prints
a string specific to the type of error, then
converts the line number to a string, and prints it.
The line number is always converted to a 4-digit hexadecimal number.
This means it won't fully work past 65,535 lines, but
let's hope we don't need to write any programs that long!

## limitations

Functions in this 03 language will probably overwrite the previous values
of registers. This can make it kind of annoying to call functions, since
you need to make sure you store away any information you'll need after the function.
And the language definitely won't be as nice to use as something with real variables. But overall,
I'm very happy with this compiler, considering it's written in a language with 2-letter label
names.

