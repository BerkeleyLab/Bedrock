# Contributing Guidelines

Entails contribution guidelines to all projects in the group hdl-libraries.
We are actively looking for meaningful contributions to our codebase. A
meaningful contribution can entail anything from:

1. A typo
2. A readability enhancement
3. A code or Makefile simplification
4. A bug report
5. A test
6. A new source file that you deem fits into this codebase and
preferably a test that goes with it!
7. Support for a new board or a chip on the existing projects
8. A new project
9. A new way to build code within the code base
10. New synthesis or simulation framework

## TL;DR

### Adding a small feature?

1. Create a branch, and write code following guidelines here
2. Add tests
3. Add them to CI, and ensure they are passing with all the other tests you may have inadvertently broken
4. Make a pull request and have somebody else other than you merge it into master
5. Feel free to request for help during any stage

### Adding a large feature?

1. Start an issue or a wiki link with a detailed feature description/request
2. Obtain general consensus or feedback
3. Create a branch, and start a Merge/Pull Request at an early stage, in order to get early feedback from community
4. Add tests
5. Add them to CI, and ensure they are passing with all the other tests you may have inadvertently broken
6. Add documentation
7. Feel free to request for help during any stage

## Code of Conduct

Behavior in this community is always expected to be professional, courteous, and constructive.
Berkeley Lab in particular mandates support of
[Inclusion, Diversity, Equity, and Accountability](https://diversity.lbl.gov/).
Please make all contributors feel welcome, assume good intent, and be considerate of others.
On-line, that often means re-reading your messages carefully before pressing "send."

Our team supports the principles and goals expressed in/by the
[Contributor Covenant](https://www.contributor-covenant.org/).
As employees of the University of California, where this project is
part of our workplace environment, it is not obvious that we have
the right to unilaterally choose, impose, or enforce such a covenant.

## Contents of a repository

A source repository should be primarily reserved for source code.
"The source code for a work means the preferred form of the work for
making modifications to it."

Occasionally binary files will creep in, for example visual images
for documentation purposes.  Each such file demands some note as to
how it was generated.

All checked-in files should be permissively licensed, consistent with
the [LICENSE.md](LICENSE.md) file.

Sometimes files are needed that can be legally downloaded from the public Internet,
but we either don't have permission to redistribute them, or we have other reasons to
not want them checked into this repository (all GPL code falls in this category,
due to guidance from University of California lawyers).  It's OK to script the
download of these files; please include a check that the result has the expected
[SHA256](https://en.wikipedia.org/wiki/SHA-2). Do NOT redistribute or embed
any files within Bedrock unless they have a suitably permissive license.
Any download steps should be visibly documented, and users are encouraged to take that step
once per repository checkout. An example (not currently in use -- that's another story) is found in
[riscv_prep.sh](build-tools/riscv_prep.sh), which downloads source files needed to build
a riscv toolchain (binutils, gcc, newlib), and is used in building our CI Docker image.

Please do NOT check-in machine generated code. If unavoidable, document it explicitly,
and give instructions for how to reproduce.

Understanding that the choice of a programming language depends on the task at hand:
Currently, synthesizable code is written in Verilog, machine-generated Verilog
typically comes from Python, test benches that are too complex for Verilog resort to Python,
and network runtime support is in Python, C, or C++.

Standard implementations and standard libraries are preferred for obvious reasons.

Automatic generation of documentation is a topic of current discussion. Suggestions welcome!


## Makefiles

We have an [explanation](build-tools/makefile.md) about how
our existing Makefiles are put together.


## Reproducible builds

All constructed files (sometimes called artifacts) should be reproducible.
See [reproducible-builds.org](https://reproducible-builds.org).  This includes pretty much any machine-generated file.

Purposefully embedded "built-on" date stamps are deprecated; use
a git commit ID (or similar) instead.

PDF and object files often take extra effort to make reproducible.

FPGA bitfiles are not typically shown to be reproducible, but Xilinx
[acknowledges](https://support.xilinx.com/s/article/61599) that is a
reasonable goal (they call it "repeatable").
Our toolchain has demonstrated this working in at least couple of cases.

## Readability

Readability is a key goal for shared software. Lowering the barrier of entry for
a newcomer enables the codebase to flourish. This can be easily achieved by adhering
to commonly accepted best practices. Although, it may be impractical to adhere to
every single best practice: reading guidelines, reviewing each others code, and
having healthy discussions can tremendously improve the standard of software.

We're not the first group to deal with this topic. The following are
useful resources:

1. [Linux kernel coding style guide](https://www.kernel.org/doc/html/v4.10/process/coding-style.html) many of the concepts it discusses have general applicability.
2. [Google python guide](https://google.github.io/styleguide/pyguide.html) and [PEP8](https://www.python.org/dev/peps/pep-0008/)
3. [GNU Coding Standards: Makefile Conventions](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html)

Please spell-check your code, comments, and documentation.

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

Trailing whitespace is pure useless entropy.

Unix-style line breaks, ASCII 0x0a.

No other control characters besides 0x0a (LF) and 0x09 (HT) in text/source files.

See comments above concerning binary files.

Tabs should not be used in any place other than the beginning of a line; doing so
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
  See [hack_xcirc](build-tools/hack_xcirc); consider creating and submitting a patch to
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

### Coding and style guidelines

In addition to the general recommendations above, we strive for a uniform
Verilog coding style that emphasizes readability, reduces systematic errors and promotes
code re-use. The [RTL Guidelines](guidelines/rtl_guidelines.md) document, which is itself
open to improvements and suggestions, attempts to formalize this process in the
form of coding and style guidelines that apply to some of the most common facets of RTL coding.

### Python

We want all python files compatible with python2 and python3.
Some legacy code can be tolerated as python2 only.
Some new code can be tolerated as python3 only.

A quick book for understanding patterns and Python in general: https://effectivepython.com/

## Testing

Ideally all code will be paired with a regression test that fully exercises
its functionality, maybe even cross-checked with a code coverage tool.
The more complex the function, the more important are such tests.

In general, file foo.v should define module foo, and have an associated
testbench in file foo_tb.v (which defines module foo_tb).  There will be
exceptions to this rule.  It's OK for other modules to be defined in
file foo.v, if they will never be instantiated by by any other code.
If possible, the testbench will give foo a thorough exercise, and print
PASS only if everything checks out.  More complex tests may involve
helper code in e.g., python, that will determine if the module is performing
as expected.  In all cases, the regression tests will be automated by
a Makefile rule called foo_check.
