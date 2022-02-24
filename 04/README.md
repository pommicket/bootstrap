# [bootstrap](../README.md) stage 04

As usual, the source for this compiler is `in03`, an input to the [previous compiler](../03/README.md).
`in04` contains a hello world program written in the stage 4 language.
Here is the core of the program:

```main()

function main
	puts(.str_hello_world)
	putc(10) ; newline
	syscall(0x3c, 0)

:str_hello_world
	string Hello, world!
	byte 0

function strlen
	argument s
	local c
	local p
	p = s
	:strlen_loop
		c = *1p
		if c == 0 goto strlen_loop_end
		p += 1
		goto strlen_loop
	:strlen_loop_end
	return p - s

function putc
	argument c
	local p
	p = &c
	syscall(1, 1, p, 1)
	return

function puts
	argument s
	local len
	len = strlen(s)
	syscall(1, 1, s, len)
	return
```

It's so simple compared to previous languages!
Importantly, functions now have arguments and return values.
Rather than mess around with registers, we can now
declare local (and global) variables, and use them directly.
These variables will be placed on the
stack. Since arguments are also placed on the stack,
by implementing local variables we get arguments for free. There is no difference
between the `local` and `argument` keywords in this language other than spelling.
In fact, the number of agruments to a function call is not checked against
how many arguments the function has. This does make it easy to screw things up by calling a function
with the wrong number of arguments, but it also means that we can provide a variable number of arguments
to the `syscall` function. Speaking of which, if you look at the bottom of `in04`, you'll see:

```
function syscall
	...
	byte 0x48
	byte 0x8b
	byte 0x85
	byte 0xf0
	byte 0xff
	byte 0xff
	byte 0xff
	...
```

Originally I was going to make `syscall` a built-in feature of the language, but then I realized that wasn't
necessary.
Instead, `syscall` is a function written manually in machine language.
We can take a look at its decompilation to make things clearer:

```
(...function prologue...)
mov    rax,[rbp-0x10]
mov    rdi,rax
mov    rax,[rbp-0x18]
mov    rsi,rax
mov    rax,[rbp-0x20]
mov    rdx,rax
mov    rax,[rbp-0x28]
mov    r10,rax
mov    rax,[rbp-0x30]
mov    r8,rax
mov    rax,[rbp-0x38]
mov    r9,rax
mov    rax,[rbp-0x8]
syscall
(...function epilogue...)
```

This just sets `rax`, `rdi`, `rsi`, etc. to the arguments the function was called with,
and then does a syscall.

## functions and local variables

In this language, function arguments are placed onto the stack from left to right
and all arguments and local variables are 8 bytes.
As a reminder,
the stack is just an area of memory which is automatically extended downwards (on x86-64, at least).
So, how do we keep track of the location of local variables in the stack? We could do something like
this:

```
sub rsp, 24      ; make room for 3 variables
mov [rsp], 10    ; variable1 = 10
mov [rsp+8], 20  ; variable2 = 20
mov [rsp+16], 30 ; variable3 = 30
; ...
add rsp, 24      ; reset rsp
```

But now suppose that in the middle of the `; ...` code we want another local variable:
```
sub rsp, 8 ; make room for another variable
```
well, since we've changed `rsp`, `variable1` is now at `rsp+8` instead of `rsp`,
`variable2` is at `rsp+16` instead of `rsp+8`, and
`variable3` is at `rsp+24` instead of `rsp+16`.
Also, we had better make sure we increment `rsp` by `32` now instead of `24`
to put it back in the right place.
It would be annoying (but by no means impossible) to keep track of all this.
We could just declare all local variables at the start of the function,
but that makes the language more annoying to use.

Instead, we can use the `rbp` register to keep track of what `rsp` was
at the start of the function:

```
; save old value of rbp
sub rsp, 8
mov [rsp], rbp
; set rbp to initial value of rsp
mov rbp, rsp

lea rsp, [rbp-8]  ; add variable1  (this instruction sets rsp to rbp-8)
mov [rbp-8], 10 ; variable1 = 10
lea rsp, [rbp-16] ; add variable2
mov [rbp-16], 20 ; variable2 = 20
lea rsp, [rbp-24] ; add variable3
mov [rbp-24], 30 ; variable3 = 30
; Note that variable1's address is still rbp-8; adding more variables didn't affect it.
; ...

; restore old values of rbp and rsp
mov rsp, rbp
mov rbp, [rsp]
add rsp, 8
```

This is actually the intended use of `rbp` (it *p*oints to the *b*ase of the stack frame).
Note that setting `rsp` very specifically rather than just doing `sub rsp, 8` is important:
if we skip over some code with a local variable declaration, or execute a local declaration twice,
we want `rsp` to be in the right place.
The first three and last three instructions above are called the function *prologue* and *epilogue*.
They are the same for all functions; a prologue is generated at the start of every function,
and an epilogue is generated for every return statement.
The return value is placed in `rax`.

## global variables

Global variables are much simpler than local ones. The variable `:static_memory_end` in the compiler
keeps track of where to put the next global variable in memory. It is initialized at address `0x500000`,
which gives us 1MB for code (and strings). When a global variable is added, `:static_memory_end` is increased
by its size.

## misc improvements

- Errors now give you the line number in decimal instead of hexadecimal.
- You get an error if you declare a label (or a variable) twice.
- Conditional jumping is much nicer: e.g. `if x == 3 goto some_label`
- Comments can now appear on lines with code.
- You don't need a `d` prefix for decimal numbers.
- You can control the input and output filenames with command-line arguments (by default, `in04` and `out04` are used).

## language description

Comments begin with `;`.

To make the compiler simpler, this language doesn't support fancy
expressions like `2 * (3 + 5) / 6`. There is a limited set of possible
expressions, specifically there are *terms* and *r-values*.

But first, each program is made up of a series of statements, and
each statement is one of the following:
- `global {name}` or `global {size} {name}` - declare a global variable with the given size, or 8 bytes if none is provided.
- `local {name}` - declare a local variable
- `argument {name}` - declare a function argument. this is functionally equivalent to `local`, so it just exists for readability.
- `function {name}` - declare a function
- `:{name}` - declare a label
- `goto {label}` - jump to the specified label
- `if {term} {operator} {term} goto {label}` - 
conditionally jump to the specified label. `{operator}` should be one of
`==`, `<`, `>`, `>=`, `<=`, `!=`, `[`, `]`, `[=`, `]=`
(the last four do unsigned comparisons).
- `{lvalue} = {rvalue}` - set `lvalue` to `rvalue`
- `{lvalue} += {rvalue}` - add `rvalue` to `lvalue`
- `{lvalue} -= {rvalue}` - etc.
- `{lvalue} *= {rvalue}`
- `{lvalue} /= {rvalue}`
- `{lvalue} %= {rvalue}`
- `{lvalue} &= {rvalue}`
- `{lvalue} |= {rvalue}`
- `{lvalue} ^= {rvalue}`
- `{lvalue} <= {rvalue}` - left shift `lvalue` by `rvalue`
- `{lvalue} >= {rvalue}` - right shift `lvalue` by `rvalue` (unsigned)
- `{function}({term}, {term}, ...)` - function call, ignoring the return value
- `return {rvalue}`
- `string {str}` - places a literal string in the code
- `byte {number}` - places a literal byte in the code
- `#line {line number} {filename}` / `#line {line number}` - set line number and optionally the filename for future errors (no code is outputted from this)

The `#line` directive (which also exists in C) seems a bit strange, but its use will be revealed soon.

Now let's get down into the weeds:

A a *number* is one of:
- `{decimal number}` - e.g. `108`
- `0x{hexadecimal number}` - e.g. `0x2f` for 47
- `'{character}` - e.g. `'a` for 97 (the character code for `a`)

A *term* is one of:
- `{variable name}` - the value of a (local or global) variable
- `.{label name}` - the address of a label
- `{number}`
- `&{variable}` - address of variable
- `*1{variable}` / `*2{variable}` / `*4{variable}` / `*8{variable}` - dereference 1, 2, 4, or 8 bytes
- `~{term}` - bitwise not

An *l-value* is the left-hand side of an assignment expression,
and it is one of:
- `{variable}`
- `*1{variable}` - dereference 1 byte
- `*2{variable}` - dereference 2 bytes
- `*4{variable}` - dereference 4 bytes
- `*8{variable}` - dereference 8 bytes

An *r-value* is an expression, which can be more complicated than a term.
r-values are one of:
- `{term}`
- `{function}({term}, {term}, ...)`
- `{term} + {term}`
- `{term} - {term}`
- `{term} * {term}`
- `{term} / {term}`
- `{term} % {term}`
- `{term} & {term}`
- `{term} | {term}`
- `{term} ^ {term}`
- `{term} < {term}` - left shift
- `{term} > {term}` - right shift (unsigned)

That's quite a lot of stuff, and it makes for a pretty powerful
language, all things considered. To test out the language,
in addition to the hello world program, I also wrote a little
guessing game, which you can find in the file `guessing_game`.
It ended up being quite nice to write!

## limitations

Variables in this language do not have types. This makes it very easy to make mistakes like
treating numbers as pointers or vice versa.

A big annoyance with this language is the lack of local label names. Due to the limited nature
of branching in this language (`if ... goto ...` stands in for `if`, `else if`, `while`, etc.),
you need to use a lot of labels, and that means their names can get quite long. But at least unlike
the 03 language, you'll get an error if you use the same label name twice!

Overall, though, this language ended up being surprisingly powerful. In fact, stage `05` will
finally be a C compiler... But first, it's time to make [something that's not a compiler](../04a/README.md).
