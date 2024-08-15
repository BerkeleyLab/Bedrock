# AXI4 Modules

The modules in this directory relate to the AMBA AXI4 bus protocol specification.
Some notes about the modules:
  1. Only AXI4-Lite is supported (so far). Contributions to push towards full AXI4 are welcome.
  2. They are written according to the published protocol specifications, but are not validated
     via e.g. formal methods.  They play nicely together and work with the AXI4-Lite Xilinx IP.
  3. AXI-related port names use the Xilinx conventions to match the heuristic-checker in the
     Vivado block diagram editor.
  4. No use is made of the AWPROT/ARPROT on host or peripheral sides
  5. The host interface (`axi_host.v`) forces all bits of WSTRB high (all bytes of WDATA are
     valid for every transaction).  The AXI-to-localbus modules (`axi_lb.v` and `axi_lb_cdc.v`)
     discard the WSTRB signal (assume all bytes of WDATA are valid for every transaction).
     The test peripheral (`axi_dummy.v`) respects WSTRB.
  6. The clock-domain-crossing `axi_cdc.v` stretches a transaction to extend the handshake across
     the domain boundary.  This works for all clock ratios, but could be optimized for a given
     ratio by simply stretching pulses as required.  By quasi-Monte-Carlo methods, this stretched
     handshake circuit adds an average of 4 cycles to each transaction (cycles being measured
     relative to the slower clock) which translates to a roughly 50% performance penalty compared
     to the single-domain solution.

__NOTE__: Some tests (`axi_lb*_tb.v`) critically depend on the pre-loaded values stored in `lb_dummy.v`,
so there is a bit of cross-dependency here.

## Wanted
  * AXI4(-Lite) Interconnect (connects multiple peripherals to a single host)
  * AXI4-to-AXI4-Lite protocol converter
  * Protocol checker (via formal methods)?
