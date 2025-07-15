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

Each top-level input port is placed in its own domain,
and output ports are not checked for errors.
This may or may not represent the demands of a specific use case.
We have written shells around the logic-under-test, that add
input and output registers to define the domain of each I/O signal.
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
you feed into yosys.  Verilog and a limited subset of SystemVerilog are OK with yosys-0.23.

## Tool flow

Our makefiles specify rules based on the following
```
foo_yosys.json: foo_shell.v foo.v worker1.v worker2.v $(BUILD_DIR)/cdc_snitch_proc.ys
	$(YOSYS) -p "read_verilog  $(filter %.v, $^); script $(filter %_proc.ys, $^); write_json $@"
foo_cdc.txt: $(BUILD_DIR)/cdc_snitch.py foo_yosys.json
	$(PYTHON) $^ -o $@
```
The chatter from that last command ends with a line like
```
OK1: 81504  CDC: 337  OKX: 1105  BAD: 97
```
counting the number of registers in each category.
The `foo_cdc.txt` file gives details, which ideally can help you find the
design errors that led to the "BAD" registers.
If the design includes any such "BAD" registers, the makefile rule for
`foo_cdc.txt` will fail, as would be used for a regression test.

## Reading the output

It's recommended to save the output of `cdc_snitch.py` in a file by
using the `-o` flag.
Call the result `foo_cdc.txt`, consistent with the make rule above.
That will usually be a big file!  But it is text, and can be understood
as described here.

Ideally, the BAD count is zero, and you don't need to look at `foo_cdc.txt`.
Otherwise, the best way to start is with
```
grep BAD foo_cdc.txt
```
Giving one line per DFF that falls in the BAD category described above.
Each of those lines will look something like
```
BAD  31049 dsp.reg_bank_2[0]:D clk lb_clk inputs ( 8 x lb_clk, 3 x dsp_clk, 1 x dsp.evr_rx_out_clk )
```
Here `dsp.reg_bank_2[0]:D` tells you that the offending path is the D input
to the 0 element of word full of DFF named (by yosys) as `dsp.reg_bank_2`.
Each net often has many different possible names, but you should be able to
find the `reg_bank_2` signal in instance `dsp` in your code.

Then it says `clk lb_clk` identifying the clock to the DFF.
Finally `inputs ( 8 x lb_clk, 3 x dsp_clk, 1 x dsp.evr_rx_out_clk )`
is a count of signals per clock domain feeding the logic.
The goal is to reduce these inputs to a single clock domain,
as described in case OK1 above.

To dive deeper, using that same example, read the whole `foo_cdc.txt`
file with `less` or your favorite text editor.  Now search for the
line discovered above with `grep`.  It is followed by more information
about that BAD DFF input.
```
BAD  31049 dsp.reg_bank_2[0]:D clk lb_clk inputs ( 8 x lb_clk, 3 x dsp_clk, 1 x dsp.evr_rx_out_clk )
  tree 31049 from 397 clk lb_clk name lb_addr_r[0]
  tree 31049 from 398 clk lb_clk name lb_addr_r[1]
  tree 31049 from 399 clk lb_clk name lb_addr_r[2]
  tree 31049 from 400 clk lb_clk name lb_addr_r[3]
  tree 31049 from 18908 clk lb_clk name dsp.fcnt_dsp_clk.work.frequency[0]
  tree 31049 from 28493 clk lb_clk name dsp.timing.evr_timestamp_valid
  tree 31049 from 28547 clk dsp_clk name dsp.evr_live_pps_tick[0]
  tree 31049 from 29201 clk dsp_clk name dsp.timing.i_oc_sync.data_out[0]
  tree 31049 from 29265 clk dsp_clk name dsp.timing.i_oc_sync.data_out[32]
  tree 31049 from 29529 clk dsp.evr_rx_out_clk name dsp.timing.i_evrAROC.evrSROCsynced
  tree 31049 from 29536 clk lb_clk name dsp.timing.i_evcnt_sync.data_out[0]
  tree 31049 from 29724 clk lb_clk name dsp.timing.fcnt_evr_clk.work.frequency[0]
```
Now instead of just a count, you can see each input to the logic cloud
identified by name and clock domain.  So `lb_addr_r[0]` comes from the
lb\_clk domain, and `dsp.evr_live_pps_tick[0]` comes from the dsp\_clk domain.

Now the real work begins: now that you know how and where good CDC hygiene
has been broken, you should fix it!  For simple command and status bits,
it's often enough to just capture them (with the OK1 topology drawn above)
into the domain in which they are used.  Other cases may be harder to
accomplish without continuing the already-present (in the BAD net)
risk of data corruption.  [Gray codes](https://en.wikipedia.org/wiki/Gray_code)
are often helpful, as are digital logic design textbooks. Good luck!

## Dependencies

Besides [cdc\_snitch.py](cdc_snitch.py) and its associated yosys command script
[cdc\_snitch\_proc.ys](cdc_snitch_proc.ys), you need:

* [yosys](https://yosyshq.net/yosys/) 0.23 or higher
* python3
* python3 json module

## Discussion

See [CDC detection with yosys](https://github.com/YosysHQ/yosys/discussions/3956),
a discussion started (with prototype code) on Sep 25, 2023.

This utility is definitely useful in its current state, and is deployed
in a [CI](https://en.wikipedia.org/wiki/Continuous_integration) context
for production HDL code.
We welcome suggestions for or work on improvements.

We're still looking for a permanent name for the attribute marking
intentional CDC registers, to replace the placeholder `magic_cdc`.
Maybe this interacts with industry standards and/or vendor-specific
attributes like `DONT_TOUCH` and `ASYNC_REG`.

Some registers will have non-clock inputs other than data (D).
That includes clock-enable (E) pins and sometimes synchronous reset (R).
Each such input is analyzed independently for clock-domain consistency.
That only makes sense, especially for R, if yosys's synthesis
results match that of the final (normally vendor-specific) synthesis.
We use yosys's "techmap" step, that creates gate-level cells for registers
with a type name based around "DFF".  We don't currently check for
DFF with asynchronous inputs, that are unlikely to be correctly handled.

Besides `cdc_snitch`, vendor tools often come with CDC analysis.
For example, Vivado `report_cdc`.
On the plus side, they will "understand" vendor-specific primitives,
and so can cover more of your design.  On the down side, they will
push using vendor-supplied IP, that will keep your design from being
easily portable to other chip families.
Having two CDC analysis tools is better than one!
