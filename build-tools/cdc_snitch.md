# cdc\_snitch Documentation

`cdc_snitch.py` is a python script which, combined with
[yosys](https://yosyshq.net/yosys/) processing of Verilog files,
can detect anti-patterns of Clock-Domain-Crossing (CDC).

We use yosys to synthesize and break down the design to registers,
combinational logic, and memories.  Using json as an intermediate
file format, `cdc_snitch.py` categorizes each register by how its
clock domain does or doesn't match the clock domains of its data sources.

## OK1

![OK1 topology](cdc_OK1.svg)

If all inputs leading to a register are in the same domain as its own
clock, that's called "OK1".  This should be the standard topology for all
real computation and state-machines.

## OKX or CDC

![OKX topology](cdc_OKX.svg)

If each input comes from a single register in another domain, so the
combinational logic is a trivial 'straight wire', that's called "OKX" or "CDC".
All real CDC circuits should be built with this topology at their core.
The default category is "OKX"; if the register has a magic CDC attribute,
then it gets labeled "CDC".  That attribute is intended to mark
_intentional_ CDC crossings.  `cdc_snitch` itself has no way to know
if such intentional CDC crossings are properly designed to avoid
data corruption.

## BAD

![BAD topology](cdc_BAD.svg)

Registers with combinational input, that get at least one input not from
its own domain, are categorized as "BAD".
Maybe this rule could be relaxed some for an ASIC, but in an FPGA
there are no expectations that the output of a LUT will be glitch-free
when inputs change.

Designs with a non-zero number of BAD registers cause `cdc_snitch.py` to
return with an error, as is relevant for a regression-testing makefile.

## Memories

Memories are a special case.  If used to cross clock domains,
the general case would necessarily mark them as "BAD" because
the inputs to the output register include the memory cells
(in the input domain) and address bits (in the output domain).
But when used properly, a data word is not written to and read from
at the same time.
So `cdc_snitch` ignores what goes on inside dual-port memories.

## I/O

Each input is placed in its own domain, and outputs are not checked for errors.
This may or may not represent the demands of a specific use case.
We have written shells around the logic-under-test, that adds
input and output registers, defining the domain of each signal.
If an input _does_ represent a physical pin, the own-domain rule
will give reasonable results.  Such a design will normally capture
the input in a simple register (placed by the synthesizer in the I/O cell),
and that's a valid "OKX" or (with attribute) "CDC".

## Verilog input

Because we call on yosys to process the source Verilog, that Verilog
needs to be portable and synthesizable, and not instantiate (closed-source,
non-synthesizable) vendor primitives.  For many reasons, we try to layer
our designs to put such constructions in an outer chip-specific layer,
with the Real Work instantiated as a portable Verilog module on the inside.
You would then point `cdc_snitch` at that inner layer.

Of course, `cdc_snitch` itself doesn't know or care what language
you feed into yosys.  Verilog and SystemVerilog are OK with yosys-0.23.

## Tool flow

Our makefiles specify rules based on the following
```
foo_yosys.json: foo_shell.v foo.v worker1.v worker2.v $(BUILD_DIR)/cdc_snitch_proc.ys
	$(YOSYS) -p "read_verilog  $(filter %.v, $^); script $(filter %_proc.ys, $^); write_json $@"
foo_cdc.txt: $(BUILD_DIR)/cdc_snitch.py foo_yosys.json
	$(PYTHON) $^ -o $@
```
The resulting `foo_cdc.txt` ends with a line like
```
OK1: 81504  CDC: 337  OKX: 1105  BAD: 97
```
and its body includes details, which ideally can help you find the
design errors that led to the "BAD" registers.
If `foo.v` includes any such "BAD" registers, the makefile rule for
`foo_cdc.txt` will fail, as would be used for a regression test.

## Dependencies

Besides [cdc_snitch.py](cdc_snitch.py) and its associated yosys command script
[cdc_snitch_proc.ys](cdc_snitch_proc.ys), you need:

* [yosys](https://yosyshq.net/yosys/) 0.23 or higher
* python3
* python3 json module

## Discussion

See [CDC detection with yosys](https://github.com/YosysHQ/yosys/discussions/3956),
a discussion started (with prototype code) on Sep 25, 2023.

This code is definitely useful in its current state.
We welcome suggestions for or work on improvements.

We're still looking for a permanent name for the attribute marking
intentional CDC registers, to replace the placeholder `magic_cdc`.
Maybe this interacts with industry standards and/or vendor-specific
attributes like `DONT_TOUCH` and `ASYNC_REG`.
