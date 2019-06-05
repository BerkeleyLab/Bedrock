Overview
========

Dummy change to test branch archiving

[Bedrock](https://gitlab.lbl.gov/hdl-libraries/bedrock/) is largely an accumulation
of Verilog codebase written over the past several years at LBNL. It contains
platform-independent Verilog, and whatever it takes to get it onto FPGA platforms like Xilinx etc.

It is currently a conglomerate of code broken into the following subdirectories:

* [dsp](https://gitlab.lbl.gov/hdl-libraries/bedrock/tree/master/dsp): Various Digital Signal Processing algorithms
implemented in platform-independent (portable) Verilog, and their test benches;
modules include DDS, Down-conversion, Up-conversion, CIC Filters,
Low-Pass filters, High-Pass filters, Mixers
* [cordic](https://gitlab.lbl.gov/hdl-libraries/bedrock/tree/master/cordic): A self contained Verilog implementation of a
[CORDIC](https://en.wikipedia.org/wiki/CORDIC);
includes several operating modes that can be selected at build-time or run-time
* rtsim: Real-Time simulation of various components of an RF system like a
resonant cavity, its Electrical and Mechanical modes, ADCs, Cables, Piezos etc.
* cmoc: Verilog implementation of an RF controller, that connects to either a
real world ADCs or simulated components within rtsim
* [badger](https://gitlab.lbl.gov/hdl-libraries/bedrock/tree/badger/badger): A real-time Ethernet/IP/UDP packet responder core in fabric
* fpga_family: Several FPGA specific constraint files
* board_support: Several board specific pin mapping related files
* projects: Instantiated projects that build and synthesize bit files that go on
FPGAs sitting on various boards that talk various platforms


A few comments regarding the codebase

1. All software is set up to easily run on *nix systems.
2. Currently everything is built using GNU Make. We are on an active lookout for
other methods.
3. iverilog is used for simulation. We are slowly starting to use [Verilator](https://www.veripool.org/wiki/verilator) as well
(see badger)
4. Xilinx tools are used for synthesis, and starting to support [YoSys](http://www.clifford.at/yosys/) (again see badger)
5. This repository is connected to Gitlab CI. All simulation based tests run
automatically upon every commit on the continuous integration server. This helps
us move faster (without breaking things)


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

Full list: Listed in https://gitlab.lbl.gov/hdl-libraries/bedrock/blob/master/dependencies.txt

On contributing
===============
See our first take [here](https://gitlab.lbl.gov/hdl-libraries/contributing-guidelines)
