Overview
========

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

************************************************************************************


### Copyright Notice

"Bedrock v1.0" Copyright (c) 2019, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from the U.S. Dept. of Energy).  All rights reserved.

If you have questions about your rights to use or distribute this software, please contact Berkeley Lab's Intellectual Property Office at: IPO@lbl.gov.

NOTICE.  This Software was developed under funding from the U.S. Department of Energy and the U.S. Government consequently retains certain rights. As such, the U.S. Government has been granted for itself and others acting on its behalf a paid-up, non-exclusive, irrevocable, worldwide license in the Software to reproduce, distribute copies to the public, prepare derivative works, and perform publicly and display publicly, and to permit others to do so.

************************************************************************************


### License Agreement

"Bedrock v1.0" Copyright (c) 2019, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from the U.S. Dept. of Energy).  All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

(1) Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

(2) Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

(3) Neither the name of the University of California, Lawrence Berkeley National Laboratory, U.S. Dept. of Energy, nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

You are under no obligation whatsoever to provide any bug fixes, patches, or upgrades to the features, functionality or performance of the source code ("Enhancements") to anyone; however, if you choose to make your Enhancements available either publicly, or directly to Lawrence Berkeley National Laboratory, without imposing a separate written license agreement for such Enhancements, then you hereby grant the following license: a non-exclusive, royalty-free perpetual license to install, use, modify, prepare derivative works, incorporate into other computer software, distribute, and sublicense such enhancements or derivative works thereof, in binary and source code form.

************************************************************************************
