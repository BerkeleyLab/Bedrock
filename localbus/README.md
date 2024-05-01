# Localbus support

Many bedrock components revolve around or depend on an on-chip
[localbus](https://en.wikipedia.org/wiki/Local_bus).
Speficially a stripped-down lightweight bus reminiscent
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

The key component held here is
Just In Time Readout Across Domains - [jit_rad](jit_rad.md) for short.

Also see
- [Lightweight Address Space Serialization](../badger/mem_gate.md)
- Bus controller for Packet Badger [mem_gateway.v](../badger/mem_gateway.v)
- Bus controller for BMB7 and QF2-pre [jxj_gate.v](../board_support/bmb7_kintex/jxj_gate.v)
- [Newad](../build-tools/newad.md)
