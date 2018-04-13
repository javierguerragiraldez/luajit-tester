# luajit-tester
A minimalistic tester script for LuaJIT development

### To run:
```
luajit tester.lua <args>
```
Where each arg is either:

- *.lua : a Lua file containing a test.
- -opt or -opt=val : sets an option, maybe with a value
- @file : reads the file, each line processed as a new argument
- anything else : a shell command to be run as a test

valid options:

- -q : quiet, don't output anything, just return success or failure
- -v : verbose, include all gathered output from each failing tests at the end.
- -e : direct all output to stderr instead of stdout.
- -f : fast fail, terminate on the first failing test.

### Lua tests

Any `.lua` file is simply loaded and executed in an ephemeral environment.  Setting global variables shouldn't affect other tests.

A successful test should simply terminate.  No return value is expected.  There's no output redirection or buffering, so `print()` statements go directly to the console.

To fail the test, signal an error, either with `error()` or `assert()`.  The error text and backtrace will be recorded and output in the verbose report.

The environment includes a few helper functions.  Alternatively, the test can `require 'tester'` and thus be runnable directly.

#### is_in(a, b)
Returns `true` if `a` is a subset of `b`, `false` otherwise.  Currently just:
```lua
function is_in(a, b)
    for k, v in pairs(a) do
        if not (v == b[k] or is_in(v, b[k])) then return false end
    end
    return true
end
```

#### deep_eq(a, b)
Deep comparison of `a` and `b`.

### Shell tests

These are executed by the system shell (using `io.popen()`).  If there's any output, it will be recorded and the test is considered a fail.  To succeed just terminate normally without any output.

### `@` files:

A long list of tests can be specified on a file, each line will be processed as an argument, even options or other `@` work just as from the command line.

A `#` character anywhere in a line starts a comment up to the end of the line.  Whitespace characters are removed at both ends of the line (after removing any `#` comment).  Empty lines are ignored.

To read from `stdin`, just don't specify any file name, just a lone `@`.  This is handy to pipe in a list of files like this:
```
find . -type f -name 't_*' | luajit tester.lua @
```
