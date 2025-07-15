## Makefiles

### Introduction
The Unix "make" program and its associated Makefiles are old,
dating to around 1976.
It's four decades later, and many of today's practical Makefiles,
including our own, seem enormously complicated.
It helps to see how they are built up from simpler ideas.

The way we use Makefiles for testing HDL and building artifacts is
slightly different from traditional pure-software projects,
but everything is still based on the same original concepts.

There are worse places to start learning about Makefiles than
[Wikipedia](https://en.wikipedia.org/wiki/Makefile).
Quoting that article, a Makefile consists of "rules" in the following form:
```
target: dependencies
	system command(s)
```
This gives the system command(s) needed to "make" target, whenever
any of the dependency files change.  Note that the line with system
command(s) on it must start with a tab character.

### Example

Our code base is based in large part on test benches written in Verilog
and simulated using Icarus Verilog, so that's what our examples will cover.
For concrete discussion purposes, consider the following Makefile:
```
all: b2d_check fib_check

# self-checking
b2d_check: b2d_tb
	vvp -N b2d_tb

b2d_tb: b2d_tb.v b2d.v
	iverilog -o b2d_tb b2d_tb.v b2d.v

# check against golden output file
fib_check: fib.out fib.gold
	cmp fib.out fib.gold
	@echo PASS

fib.out: fib_tb
	vvp -N fib_tb > $@

fib_tb: fib_tb.v fib.v
	iverilog -o fib_tb fib_tb.v fib.v

```
This covers two cases: one where b2d_tb is a self-checking testbench,
i.e., where execution of b2d_tb ends with $stop(0) on failure,
but $finish(0) on success.
In the other case, fib_tb creates an output file that needs to match fib.gold.

Normally, the make program displays each command before it is executed.
This is considered a good thing, because it helps isolate the
cause of any failures that occur.
Referring to the fib_check rule above, the second command
```
echo PASS
```
is only executed if the first one succeeds.  It is not helpful to see this
command, only its result; the prefix @ prevents the usual echo in this case.

### Generalization

The above Makefile can be generalized using
[pattern rules](https://www.gnu.org/software/make/manual/html_node/Pattern-Rules.html)
and special Makefile macros.  Quoting Wikipedia again:

 *  $@ is a macro that refers to the target
 *  $< is a macro that refers to the first dependency
 *  $^ is a macro that refers to all dependencies

The previous Makefile turns into:
```
%_check: %_tb
	vvp -N $<

%_tb: %_tb.v
	iverilog -o $@ $^

%.out: %_tb
	vvp -N $< > $@

all: b2d_check fib_check

fib_check: fib.out fib.gold
	cmp $^
	@echo PASS

b2d_tb: b2d.v

fib_tb: fib.v

```

### Configurability

The next layer of indirection allows command-line overrides of strings used
in the Makefile.  In particular,
```
VERILOG = iverilog
%_tb: %_tb.v
        $(VERILOG) -o $@ $^
```
will allow the user to change versions of iverilog on-the-fly, without
editing the Makefile, with the command line
```
make VERILOG=iverilog-0.10
```
In fact, our setup normally specifies
```
VERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
```
allowing a simple
```
make ICARUS_SUFFIX=-0.10
```
to configure both the iverilog and vvp version used.

### Makefile includes

Finally, we normally take all the generic definitions and put
them in a single file called top_rules.mk, which can be shared
by the individual Makefiles scattered around in various directories.
So a stripped down version of top_rules.mk looks like
```
VERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
GTKWAVE = gtkwave
VFLAGS =

%_check: %_tb
	$(VVP) -N $<

%_tb: %_tb.v
	$(VERILOG) $(VFLAGS) -o $@ $^

%.out: %_tb
	$(VVP) -N $< > $@

%.vcd: %_tb
	$(VVP) -N $< +vcd

%_view: %.vcd %.gtkw
	$(GTKWAVE) $^

```
and the Makefile that references it looks like
```
include top_rules.mk

all: b2d_check fib_check

fib_check: fib.out fib.gold
	cmp $^
	@echo PASS

b2d_tb: b2d.v

fib_tb: fib.v

clean:
	rm -f *_tb *.vcd *.out

```
Here we have added two new features: rules to create and display
timing diagrams using gtkwave, and the traditional "clean" rule to
remove generated files.

### Dependencies

What's not covered here is dependency derivation and/or management, something
that gets increasingly complicated as the number of files involved climbs.
One approach we use is based on combining the -y and -M options to iverilog.
The -y flag will cause iverilog to
search directories for files that match unresolved module names.
The -M flag emits a list of files used, which
can be converted to a dependency list for make.

### One more trick

The $@ symbol (target name) can be used to pull in
extra configuration for commands.
The setup starts by adding an extra element to the
generic VFLAGS definition:
```
VFLAGS = ${VFLAGS_$@}
```
That gives us a hook to let a specific testbench target add
additional parameters, like this:
```
VFLAGS_b2d_tb = -m ./udp-vpi
```
This example causes an extra module to be loaded when building b2d_tb,
without perturbing the commands to build other _tb targets.

### Discussion

There have been [many attempts](https://en.wikipedia.org/wiki/List_of_build_automation_software),
continuing today, to build on, enhance, or replace make.
Two in particular attempt to address the needs of an HDL environment.

 * [Hdlmake](https://ohwr.org/project/hdl-make/-/wikis/home)
 * [FuseSoC](https://pypi.org/project/fusesoc/)

Our experiments with these tools have generally been frustrating.
We use the flexibility of make to support many combinations
of target hardware and application code, as well as manage generated code
and self-tests.  Such capabilities are not priorities of these
more specialized tools.

### Cross-check

A demo "project" using the example Makefiles above produces the
following output:
```
iverilog -o b2d_tb b2d_tb.v b2d.v
vvp -N b2d_tb
result           x for input     x
result         123 for input   123
result         123 for input   123
result       60875 for input 60875
result       13604 for input 13604
result       24193 for input 24193
result       54793 for input 54793
result       22115 for input 22115
result       31501 for input 31501
result       39309 for input 39309
result       33893 for input 33893
result       21010 for input 21010
         12 tests passed
PASS
iverilog -o fib_tb fib_tb.v fib.v
vvp -N fib_tb > fib.out
cmp fib.out fib.gold
PASS

```
The three Makefiles above are all equivalent, in the sense that they produce
the same output (when whitespace is ignored).
