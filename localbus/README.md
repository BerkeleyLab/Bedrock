# Localbus support

Many bedrock components revolve around or depend on an on-chip
[localbus](https://en.wikipedia.org/wiki/Local_bus).
Specifically a stripped-down lightweight bus reminiscent
of a VME A24 bus.

In a given clock domain, expect
- 24-bit address
- 32-bit write data
- 32-bit read data
- strobe and read/write

Unlike more exotic and complex busses like AXI and Wishbone,
we specifically reject any idea of wait states and handshake.
Our use case covers real-time on-chip communication,
where cycle counts are well-defined and set at configuration/synthesis
time, _not_ run-time.

Components held here are
- Just In Time Readout Across Domains - [jit_rad](jit_rad.md) for short.
- localbus.vh, a helper for cycle-accurate bus simulations
- gen_regmap.py
- the much-maligned tgen, a general-purpose real-time write sequencer,
 constructed as a localbus interposer;
 has support in leep as assemble_tgen() and tgen_reg_sequence()

As the jit_rad documentation explains, it's easy to shift the *write*
side of a localbus to a different clock domain.  Throughput is not affected,
and the additional latency and jitter are typically irrelevant
compared to what goes on in the software and LASS host computer.
Here are the typical few lines of Verilog we use to accomplish this
clock domain shift (extracted from cmoc/cryomodule.v):
```
wire [31:0] clk1x_data;
wire [16:0] clk1x_addr;
wire clk1x_write;
// Transfer local bus to clk1x domain
data_xdomain #(.size(32+17)) lb_to_1x(
.clk_in(lb_clk), .gate_in(lb_write), .data_in({lb_addr,lb_data}),
.clk_out(clk1x), .gate_out(clk1x_write), .data_out({clk1x_addr,clk1x_data}));
```

Also see
- [Memory gateway timing](../badger/doc/mem_gateway.svg)
- [Lightweight Address Space Serialization](../badger/mem_gate.md)
- Bus controller for Packet Badger [mem_gateway.v](../badger/mem_gateway.v)
- Bus controller for BMB7 and QF2-pre [jxj_gate.v](../board_support/bmb7_kintex/jxj_gate.v)
- [Newad](../build-tools/newad.md)
