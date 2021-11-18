# stage 04a

Rather than a compiler, this stage only consists of a simple [preprocessor](https://en.wikipedia.org/wiki/Preprocessor).
In the future, we'll run our code through this program, then run its output
through a compiler.

It take lines like:
```
#define THREE d3
```
and then replaces `THREE` anywhere in the rest of the code with `d3`.
I've provided `in04a` as a little example.
Unlike previous programs, you can control the input and output file names
without recompiling it. So to compile the example program:
```
make out03
./out03 in04a out04a
```

Although it seems simple, this program will be very useful:
it'll let us define constants and it'll work in any language.
There really isn't much else to say about this program. With that,
we can move on to [the next stage](../04b/README.md) which should be more exciting.
