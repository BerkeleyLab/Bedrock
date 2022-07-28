Overview
========

Bedrock generated documentation: https://berkeleylab.github.io/Bedrock

[Bedrock](https://gitlab.lbl.gov/hdl-libraries/bedrock) is largely an accumulation
of Verilog codebase written over the past several years at LBNL. It contains
platform-independent Verilog, and whatever it takes to get it onto FPGA platforms like Xilinx etc.

It is currently a conglomerate of code broken into the following subdirectories:

* [dsp](dsp): Various Digital Signal Processing algorithms
implemented in platform-independent (portable) Verilog, and their test benches;
modules include DDS, Down-conversion, Up-conversion, CIC Filters,
Low-Pass filters, High-Pass filters, Mixers
* [cordic](cordic): A self contained Verilog implementation of a
[CORDIC](https://en.wikipedia.org/wiki/CORDIC);
includes several operating modes that can be selected at build-time or run-time
* rtsim: Real-Time simulation of various components of an RF system like a
resonant cavity, its Electrical and Mechanical modes, ADCs, Cables, Piezos etc.
* cmoc: Verilog implementation of an RF controller, that connects to either a
real world ADCs or simulated components within rtsim
* [badger](badger): A real-time Ethernet/IP/UDP packet responder core in fabric
* fpga_family: Several FPGA specific constraint files
* board_support: Several board specific pin mapping related files
* projects: Instantiated projects that build and synthesize bit files that go on
FPGAs sitting on various boards that talk various platforms


A few comments regarding the codebase

1. All software is set up to easily run on *nix systems.
2. Currently everything is [built using GNU Make](build-tools/makefile.md).
We are on an active lookout for other methods, if they're actually better for us.
3. iverilog is used for simulation. We are slowly starting to use [Verilator](https://www.veripool.org/wiki/verilator) as well
(see badger)
4. Xilinx tools are used for synthesis, and starting to support [YoSys](http://www.clifford.at/yosys/) (again see badger)
5. This repository is connected to Gitlab CI. All simulation based tests run
automatically upon every commit on the continuous integration server. This helps
us move faster (without breaking things)


Graphical x Batch mode
======================

Bedrock is structured in such a way to make use of traditional *nix
tools, suck as `make` and `grep`, bash-like and python scripts from the
command-line. This makes it easy to automate the build process, customize
steps and gives flexibility to add hooks for generating code, stubs,
definitions and much more.

However, there are valid cases for using a graphical, interactive
interface such as: analyzing eleborated, synthesized or implemented
design schematic; adding/removing placement constraints;
customizing a block design; customizing an IP core from a vendor.

Bedrock keeps all the vendor-specific generated files in a _<VENDOR_NAME>
directory in the synthesis directory. So, for instance, when synthesizing
a design for `Xilinx`, Bedrock scripts will create a directory called
`_xilinx` with the unmodified vendor files within.

In this way, after the vendor project file is created (see the [build-tools discussion](build-tools/makefile.md) for details), one can simply invoke the
vendor tool manually with the project file name as the argument.

For instance, if using Vivado, one can use the following command
to open a project in Graphical mode:

```bash
vivado <PROJECT_DIRECTORY>/_xilinx/<TOP_LEVEL_DESIGN_NAME>/<TOP_LEVEL_DESIGN_NAME>.xpr
```

in which `<PROJECT_DIRECTORY>` is the direcotry in which you invoked
`make` and `<TOP_LEVEL_DESIGN_NAME>` is the bitstream name without the
`.bit` extension.

Dependencies
============

Required:

*  GNU Make
*  iverilog
*  Python

Recommended:

*  GTKWave
*  Xilinx Vivado
*  Verilator
*  YoSys

Full list: see [dependencies.txt](dependencies.txt) and [Dockerfile](Dockerfile).

On contributing
===============
See our first take [here](guidelines/CONTRIBUTING.md)

************************************************************************************


### Copyright Notice and License Agreement

See [LICENSE](LICENSE.md).
