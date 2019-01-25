Overview
========

[Bedrock](https://gitlab.lbl.gov/hdl-libraries/bedrock/) is largely an accumulation
of verilog codebase written over the past several years at LBNL. It largely contains
platform independant Verilog, and whatever it takes to get it onto FPGA platforms like Xilinx etc.

It is currently a conglomerate of code broken into the following subdirectories:

* [dsp](Bedrock/dsp): Various Digital Signal Processing Verilog code
(And their test benches) like DDS, Downconversion, Upconversion, CIC Filters,
Low-Pass filters, High-Pass filters, Mixers
 
* cordic: A self contained Verilog implementation of a
[cordic](https://en.wikipedia.org/wiki/CORDIC)

* rtsim: Real-Time simulation of various components of an RF system like a
resonant cavity, it's Electrical and Mechanical modes, ADCs, Cables, Piezos etc.

* cmoc: Verilog implementation of an RF controller, that connects to either a
real world ADCs or simulated components within rtsim

* badger: A real-time ethernet packet responder

* fpga_family: Several FPGA specific constraint files 

* board_support: Several board specific pin mapping related files

* projects: Instantiated projects that build and synthesize bit files that go on
FPGAs sitting on various boards that talk various platforms


A few comments regarding the codebase

1. All software is setup to run easily on *nix systems.
2. Currently everything is build using GNUMake. We are on an active lookout for
other ways.
3. iverilog is used for simulation. We are starting to use Verilator as well
(see badger)
4. Xilinx for synthesis, and starting to support YoSys (again see badger)
5. This repository is connected to Gitlab CI. All simulation based tests run
automatically upon every commit on the continuous integration server. This helps
us move faster (without breaking things)


Dependencies
============

Required:
*  GNU Make
*  iverilog
*  Python2/3

Recommended:
*  Xilinx installed somewhere
*  Verilator
*  YoSys

Full list: Listed in https://gitlab.lbl.gov/hdl-libraries/bedrock/blob/master/dependencies.txt

On contributing
===============
See our first take [here](https://gitlab.lbl.gov/hdl-libraries/contributing-guidelines)
