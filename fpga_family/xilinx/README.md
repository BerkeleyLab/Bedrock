# Simple generic Xilinx primitives

Mostly substitutes for the trivial Xilinx primitives that somehow sneak into
otherwise simulatable code.  Avoids needing a copy of Xilinx tools for
simple simulations.

The following are arguably correct for RTL simulation.
Some restrictions may apply.

* BUFGCE.v
* BUFG_GT.v
* BUFG.v
* BUFH.v
* BUFIO.v
* FD.v
* IBUFDS_GTE2.v
* IBUFDS_GTE4.v
* IBUFDS.v
* IBUFGDS.v
* IBUF.v
* IDDR.v
* IOBUF.v
* OBUFDS.v
* OBUF.v
* ODDR.v

The following are not; they may or may not have some utility other
than acting as a placeholder in dependency generation and linting.

* BUFR.v
* IDELAYE2.v
* MMCME2_BASE.v
* MMCME4_ADV.v

One more file is an encapsulation of some Xilinx primitives
that has been reused in a few designs

* xilinx7_clocks.v
