## COMMS TOP

The main purpose of this Bedrock project is to serve as a reference on how to set up
multiple serial link protocols based on the TCL-based Quad MGT instantiation flow.

Additionally, as part of the CI/CD, it provides coverage and protects against
regressions in the following Bedrock sub-systems and features:

* Ethernet to Local Bus bridge over fiber
* ChitChat serial protocol over fiber
* Generation of QF2PRE-compatible bitfiles
* Communication with QF2PRE over Ethernet/Local Bus

**NOTE:** While this project mainly focuses on exercising QF2PRE hardware and its
GTX transceivers, a minimal example of Ethernet-over-fiber functionality using GTP
transceivers can be found under `gige_eth/`, which targets an AC701 development board.

> Generate bitfile:

`make comms_top.bit`

> Load bitfile:

```
python -m qf2_python/scripts/program_kintex_7 -b comms_top.bit

TODO: Integrate into Makefile/CI
```

> Run hardware test:

`make hwtest`


# Architecture

`comms_top.v` consists of an Ethernet to Local Bus bridge running over a Fiber link at 1.25 GBd
and a ChitChat link also routed through a Fiber link at 2.5 GBd. Limited test-pattern
generation is provided, with the Ethernet/Local Bus guaranteeing the interface with the Host.

## Ethernet and Local Bus

`eth_gtx_bridge.v` combines packet Badger with PCS/PMA logic and a GTX interface. This module
performs its own 8b/10b line coding and, as such, outputs 20-bits of raw data to the GTX.

Packet Badger is clocked at 125 MHz, while the GTX interface is clocked at 62.5 MHz.
Data width/rate conversion is performed within `eth_gtx_bridge.v`.

Two clock managers are used to convert the 125 MHz `{tx,rx}outclk_out` clock outputs from
the TX and RX GTXs to half-rate, 62.5 MHz.

The Local Bus interface is on the `gmii_tx_clk` domain and expects fixed-latency read responses.

A bare-bones register bank, `comms_top_regbank.v`, decodes incoming Local Bus commands and writes
and reads to a pre-defined set of registers which provide access to the ChitChat core.

## ChitChat

`chitchat_txrx_wrap.v` implements a pair of TX/RX endpoints running the ChitChat protocol, along
with the necessary clock domain crossing between the following clock domains:

* `tx_clk`
* `rx_clk`
* `lb_clk`
* `gtx_tx_clk`
* `gtx_rx_clk`

To emulate its typical use, TX data is clocked in at a lower rate (`sys_clk` - 50 MHz) than the
TX/RX rates (125 MHz). Both return data and RX registers are clocked at `lb_clk`(125 MHz).

The ChitChat wrapper relies on the GTXs to perform 8b/10b line coding. Comma characters are
periodically transmitted and indicated by the `gtx_{tx,rx}_k` qualifier.

# MGT Setup

The two serial protocols used in this design communicate over two independent MGTs co-located in
the same Quad. Their configuration is entirely contained within `gtx_comms_top.tcl`, which is the
entry point to the TCL-based MGT configuration flow described below.

## TCL-based MGT configuration

The Quad MGT used in this system is configured with a TCL-based flow, essentially comprised of a
TCL configuration script, `mgt_gen.tcl` and a QGT Verilog wrapper, `qgt_wrap.v`.

`mgt_gen.tcl` implements two user-facing procedures:

* `proc add_aux_ip {ipname config_file module_name}`
* `proc add_gt_protocol {config_file quad_num gt_num en8b10b pll_type}`

`add_aux_ip` provides a convenient way of adding arbitrary IP, that would otherwise have to be
generated manually through the GUI wizard.

`add_gt_protocol` can be used to configure up to 4 Quad MGTs at MGT granularity. `config_file` specifies
a TCL file containing a dictionary with all configuration parameters for a specific MGT. The remaining
arguments associate the configuration with a specific MGT in the chip and set options that are used in
the generation of the final Verilog modules (`q0_gt_wrap`, `q1_gt_wrap`, `q2_gt_wrap`, `q3_gt_wrap`),
which all remain in `qgt_wrap.v`.

`qgt_wrap.v` makes extensive use of Verilog macros to generate the correct code in the presence of
different configuration parameters. These are defined in `qgt_wrap_stub.vh` and `qgt_wrap_pack.vh` and
are selectively activated based on compile-time defines set by `mgt_gen.tcl`.

> An expanded version of `qgt_wrap.v` can be generated, for debug purposes or otherwise, by running:

`bedrock/fpga_family$ make qgt_template`


# (Self-)Testing

A basic test-pattern generator feeds Chitchat with a looping stream of well-known data. The data
consists of two ASCII strings that can be easily identified when read from the Host over Local Bus.

Note that the transmitted data is currently not tested for correctness on the RX side.

`comms_top_test.py` allows configuration registers to be accessed over UDP.
This test script contains a basic parser for 'command files' which can be used to quickly
create test cases composed of sequences of localbus commands, along with a few meta-commands.
The following commands are currently supported:

* `RDW :ADDR`
* `WRW :ADDR DATA`
* `PRINT "STRING"`
* `CMP :ADDR EXPECTED_VALUE`
* `WAIT TIME_IN_SECONDS`

A somewhat self-checking 'command file' is run with `make hwtest`. While not an exhaustive test,
it is capable capable of finding basic issues with the ChitChat link, localbus decoding
and, by implication, Ethernet over fiber.
