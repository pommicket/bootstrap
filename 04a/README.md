# [bootstrap](../README.md) stage 04a

Rather than a compiler, this stage only consists of a simple [preprocessor](https://en.wikipedia.org/wiki/Preprocessor).
In the future, we'll run our code through this program, then run its output
through a compiler.

It takes lines like:

```
#define NUMBER 349
```

and then replaces `NUMBER` anywhere in the rest of the code with `349`.
Also, it lets you "include" files in other files. The line

```
#include other_file.txt
```

will put the contents of `other_file.txt` right there.

But wait! If we mess around with source code for our 04 compiler
with a preprocessor, we could screw up the line numbers
in error messages! This is where the `#line` directive from the 04 language comes in.

Let's take a look at the source files `in04a`:

```
#define H Hello,
#include test_inc
H W!
```

and `test_inc`:

```
#define W world
```


When `in04a` gets preprocessed, it turns into:

```
#line 1 in04a

#line 1 test_inc

#line 3 in04a
Hello, world!
```

As we can see, the preprocessor sets up a `#line` directive to put `Hello, world!`
on the line where `H W!` appeared in the source file.

Although this program is quite simple, it will be very useful:
we can now define constants and split up our programs across multiple files.

One intersting note about the code itself: rather than create a large
global variable for the `defines` list, I decided to make a little `malloc`
function. This uses the `mmap` syscall to allocate memory.
The benefit of this is that we can allocate 4MB of memory without 
adding 4MB to the size of the executable. Also, it lets us free the memory
(using `munmap`),
which isn't particularly useful here, but might be in the future.

Note that replacements will not be checked for replacements, i.e. the code:

```
#define A 10
#define B A
B
```

Will be preprocessed to `A`, not `10`.
