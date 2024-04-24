# jit_rad: Just In Time Readback Across Domains

Demo of an idea for efficiently making data from another clock domain
available to local bus readout, without violating CDC checks

The simple localbus used in bedrock and lcls2_llrf makes a lot of things
easy at the Verilog source level, with minimal FPGA fabric footprint.
In particular, localbus writes to a large number of registers in a handful
of clock domains can be handled effectively and correctly.  This is done
by making a whole copy of the (lightweight) bus in each such domain, and
then implementing the register writes and decoding in the proper domain.
A few cycles of latency are added, but since this is all about software
control over the network, and software and the network are not real-time
to begin with, that's not a problem.

Reading results from clock domains other than the primary is harder, because
the memory gateway requires a synthesis-time choice of the exact number of
clock cycles latency.  Our typical practice is to just ignore CDC problems,
and hope that registers in domain B are not corrupted when read in domain A.
This module attempts to address that design flaw.

We have a fair amount of warning at the beginning of a LASS UDP packet
before any actual read cycles happen.  Our strategy is to copy 16 words
from the app_clk domain into a 16x32 (distributed) dpram.  Then those
data are trivially available to read out in the local bus domain.

In a QF2-pre, we get about 300 ns warning, because cycles are slow (20 ns),
and packets start with eight bytes of nonce.  With Packet Badger, the raw_l
signal comes up about 352 ns before the client receives any data.
In either case, we have time to cycle the application side
(adc_clk in the case of lcls2_llrf) 16 times to read 16 values
into the dpram mentioned above.

Unlike the existing (broken CDC) case, it's not possible to repeatedly
poll a signal within the same packet.  Well, you can, but you're guaranteed
to get the same answer each time.  Unlike our slow-readout scheme, the
data read is not a single-time atomic snapshot.  On the plus side,
its hardware footprint is pretty small, and I claim it can be dropped in
to lcls2_llrf without requiring any changes to high-level code.

If you really want or need atomic capture, a hook is provided that lets you
do that.  See the demo code, described below.

Some use cases merge localbus requests from the network with locally
generated requests from e.g., a soft core.  That could get messy, if
the soft core and network both need access to the cross-domain registers.

## Code

jit_rad_gateway.v is the primary module of interest.
It attaches to the main localbus with traditional signals:
- lb_clk 
- lb_addr
- lb_strobe
- lb_data (result)

Then there's the connection to the external 16-in 32-bit wide multiplexer
- xfer_clk
- xfer_strobe
- xfer_addr
- xfer_odata (result)

The parameter "passthrough" either enables full functionality (default)
or directly connects the multiplexer signals to the localbus,
matching old-style (broken CDC) behavior.
The other ports are
- app_clk (normally routed to xfer_clk),
- lb_prefill (which triggers the transfer of data into the dpram),
- xfer_snap (supporting atomic capture use cases)
- lb_error (output bit which might detect violations in the timing assumptions).

A full demo of this system is in jit_rad_gateway_demo.v.  That consists
of a production local bus controller (jxj_gate or mem_gateway, preprocessor-
selectable), an instantiation of jit_rad_gateway, the external multiplexer
in the xfer_clk domain, and some minimal localbus implementation so you can
see activity.

A Verilator driver for jit_rad_gateway_demo is in xfer_sim.cpp, that can
put the simulated chip on a live localhost UDP socket.  A WIP iverilog
test bench is in jit_rad_gateway_tb.v.

Most of the other files here (besides this one, and the Makefile) are copies
of files from scattered locations in bedrock, maybe with a few mods.

## Prerequisites and usage

Assume for the moment you're running on a full-featured Linux development box,
with modern copies of iverilog, verilator, and yosys installed.  I tested
on Debian Stable (12.5) with stock copies of those programs.  Then a basic
"make" command here will
- check syntax with iverilog (of both QF2 and Packet Badger configurations)
- test CDC-correctness
- build a Verilator-based simulator (Vjit_rad_gateway_demo) that can
  attach to a live UDP port
- build and run an iverilog-based simulation, that should eventually
  perform functional regression tests

Note that attribute handling in yosys was only recently fixed.
yosys-0.38 and later versions work fine, but yosys-0.37 and earlier
lose track of the magic_cdc attribute because of attribute settings
in jxj_gate.v, resulting in misleading output from cdc_snitch.

Just for fun, set the default passthrough parameter to 1 in jit_rad_gateway.v,
and re-run the CDC test.  It will fail badly!

To run the live simulator, in one console:
```
make live
```
then at another console:
```
PYTHONPATH=$BEDROCK/badger sh stim.sh
```
where PYTHONPATH is set up to gain access to lbus_access.py.
This can be followed by
```
gtkwave xfer_demo.vcd xfer_demo.gtkw
```

# To do:

- clean up this documentation
- document acceptable relationship between lb_clk and app_clk
- finish up the regression check
- test it out for real in lcls2_llrf
