Bash Pre-Processor
==================

[![Circle CI](https://circleci.com/gh/iwonbigbro/bashpp.svg?style=svg)](https://circleci.com/gh/iwonbigbro/bashpp)

There are certain instances where you need to statically include other scripts
within a primary single script.  For example, RPM spec %pre scripts can't
utilise any scripts that are deployed during the installation of an RPM,
because those scripts just simply aren't available.  In those situations, you
need a mechanism through which you can perform CPP style static inclusions of
other files.  The Bash Pre-Processor hopes to solve this problem, by providing
the functionality of the C Pre-Processor, targeted at Bash scripts.

This tool is written in Bash, so itt may not perform as well as other scripts
written in Python or Perl, but Bash Pre-Processor aims to be as portable as
possible, requiring only Bash and core utilities.

Controlling Bash Pre-Processor
------------------------------
You can control the behaviour of the Bash Pre-Processor through the use of
environment variables or through command line switches.

Supported Directives
--------------------

### #include <filename>
Include a file defined in the standard include path, defined by the BASHINC
environment variable or paths specified with the `-I dir` flag.

### #include "path/filename"
Include a file relative to the directory of the file being processed.  If the
path starts with a forward slash, then the path is searched relative to the
root file system.

### #define NAME VALUE
Create a new definition.  If NAME is already defined, `bashpp` will terminate
with an error message.

### #undef NAME
Undefine the NAME definition if defined.  If NAME is not defined, NAME will
remain undefined.

### #ifdef NAME
If NAME is defined, everything that follows to the `#endif` or `#else` statement
is written to the output file.  If NAME is undefined, everything that follows is
omitted.

### #ifndef NAME
Negated implementation of `#ifdef`

### #else
Inverse of the preceding `#ifdef` or `#ifndef` expression.

Command Line Options
--------------------

For command line options, see the usage by running:

```none
$ bashpp --help
```

Here are the options as of 7 Aug 2015.

```none
Usage: bashpp [options] file...
Options:
  -I dir                Add the directory defined by dir to the include path.

  -D name               Predefine name as a macro, with definition 1.

  -D name=definition    The contents of definition are tokenized and processed
                        as if they appeared during translation in a #define
                        directive.

                        If you are invoking the preprocessor from a shell or
                        shell-like program you may need to use the shell's
                        quoting syntax to protect characters such as spaces that
                        have a meaning in the shell syntax.

                        -D and -U options are processed in the order they are
                        given on the command line.

  -o file               Place the output into <file>

  -v                    Verbose mode.

Arguments:
    file                Specify an input file.  By default, input is read from
                        standard input.

Copyright (C) 2015 Craig Phillips.  All rights reserved.
```
