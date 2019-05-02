# Contributing Guidelines

Entails contribution guidelines to all projects in the group hdl-libraries.

## TL;DR

0. Read this document.
1. Follow readability guidelines
2. Add tests
3. Make a pull request when merging into master


## Contents of a repository

A source repository should be primarily reserved for source code.
"The source code for a work means the preferred form of the work for
making modifications to it."

Occasionally binary files will creep in, for example visual images
for documentation purposes.  Each such file demands some note as to
how it was generated.

All checked-in files should be permissively licensed, consistent with
the license.txt file.

If a file is needed that can be legally downloaded from the public Internet,
but not redistributed, a Makefile rule (or similar mechanism) can be included
to perform that download and check that the result has the expected SHA256.
This step should be visibly documented, and users encouraged to take that step
once per repository checkout.

Sometimes files that look like source are actually machine generated.
This can be very good, when it minimizes the chances of it having
hard-to-detect errors.  It can also be confusing, and the worst case
is to have a long (but correct-by-construction) file checked in to
the source repository, which has then been hand-edited such that correctness
can no longer be guaranteed.  Usually the best approach is to use
Makefiles to generate these files on-the-fly.  If they are checked
in, they should be both visibly marked at the top as machine-generated,
and have some cross-check rule that confirms they still have the
expected contents.


## Reproducible builds

All constructed files (sometimes called artifacts) should be reproducible.
See [reproducible-builds.org](https://reproducible-builds.org).  This includes pretty much any machine-generated
file, including pseudo-source files discussed above.

Purposefully embedded "built-on" date stamps are deprecated; use
a git commit ID (or similar) instead.

PDF and object files often take extra effort to make reproducible.

FPGA bitfiles are not typically shown to be reproducible, but it would
be great if that can change.

## Readability

Readability is a key goal for shared software. Lowering the barrier of entry for
a newcomer enables the codebase to flourish. Hence it is important to keep code
readable. And this can be easily achieved by adhering to commonly accepted best
practices. Although, it maybe impractical to adhere to every single best
practice: reading guidelines, reviewing each others code, and having healthy
discussions can tremendously improve the standard of software.

This section contains a few rules of thumb, with some language specific
guidelines.  We're not the first group to deal with this topic.  The
[Linux kernel coding style guide](https://www.kernel.org/doc/html/v4.10/process/coding-style.html)
is a useful background read; many of the concepts it discusses have
general applicability.


### A few rules of thumb

#### Naming
(This includes traditional function and variable names in compiled languages
like C, as wall as the various user-created names in Python, and wires,
regs, and module names in Verilog)

In most use cases and languages, please avoid CamelCase. You can resort to
snake_case instead to enhance readability of long names.

See Linux coding style "4) Naming".  Pay attention to the namespace.
Use names that are easy to read and type, and that are not too hard to
grep for.

If you can reuse an existing name, for instance in Verilog using
the same name for a reg and the port name of a module that receives
that value, please do so.  Creating new and slightly different names
for the same thing is a wasteful cognitive load.


#### Whitespace
Readability is the goal, and specialized techniques to gain readability
(like vertical alignment of parallel semantics) is allowed and even encouraged.

Trailing whitespace is pure useless entropy, just don't.

Unix-style line breaks, ASCII 0x0a.

No other control characters besides 0x0a (LF) and 0x09 (HT) in text/source files.

See comments above concerning binary files.

Tabs should not be used any place other than the beginning of a line; doing so
invites "tab damage".  OTOH, using tabs consistently at the beginning of lines
to represent logical indentation level has advantages; people's setting of tab
width can systematically and locally adjust the visual indentation level. Just
like Wikipedia's English vs. American spelling policy, don't gratuitously
change the tab vs. spaces convention of a file.  See also
[Silicon Valley - S03E06 - Tabs versus Spaces](https://www.youtube.com/watch?v=SsoOG6ZeyUI) (2:50).

Special case for python files:
  No tabs, per [PEP8](https://www.python.org/dev/peps/pep-0008/)

Special case for Makefiles:
  Semantic tabs

Special case for Xcircuit PostScript files:
  See [hack_xcirc](hack_xcirc); consider creating and submitting a patch to
avoid this in the distant future.


### Verilog

#### Of syntax
Verilog files should always start with a human-readable description of
its function.  Adding a template giving name, version, and author is
discouraged; that's what we have version control for.

Use ANSI-C style port naming, as introduced in Verilog-2001.
Suggest a high proportion of comments connected with the port definitions.

Pay extra attention to module names, that are global in Verilog,
see "Universal considerations for names" above.

Pay extra attention to "8) Commenting" in Linux kernel style guide.

Verilog include files should use ".vh" as the name suffix.

Suggest, but do not mandate, tabs for logical indentation level, see above.

Verilog modules tend to be longer on average than C functions.  This is partially
an unfortunate consequence of the limitations of Verilog and the overhead involved
in constructing a new layer/module.  That is no excuse for pathologically long
and complicated modules, that egregiously violate Linux style guide section
"6) Functions".  Please find ways to break up and/or autogenerate those modules.

Please delete the 8-line header in GtkWave config files (.sav or .gtkw), that
contains username and absolute path info.  Consider creating and submitting a
patch to gtkwave.

#### Of semantics

Most of our effort should be focused on portable synthesizable Verilog modules
and their testing.  FPGA-specific instantiations (e.g., clock management and
MGTs) should be separated from our functional code.  Too-tight a connection
between them gets in the way of testing, since the Xilinx-supplied models are
non-redistributable and sometimes encrypted.

Portable synthesizable code should be written in a way that makes the hardware
representation clear to both humans and the synthesizer.  All logic, flip-flops,
multipliers, and RAM should be inferred.

Most of our code is intended to run at relatively high clock rates.  Even
modules that don't actually need high throughput are often put in a clock
domain shared with high-throughput logic.  This consideration necessitates
strongly pipelined logic.

### Python

We want all python files compatible with python2 and python3.
Some legacy code can be tolerated as python2 only.
Some new code can be tolerated as python3 only.


## Testing

Ideally all code will be paired with a regression test that fully exercises
its functionality, maybe even cross-checked with a code coverage tool.
The more complex the function, the more important are such tests.
