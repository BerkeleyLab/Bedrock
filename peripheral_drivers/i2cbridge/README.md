# Yet another I2C (really TWI) bridge/controller/interface

Larry Doolittle, LBNL, August 2018

## Primary goals

* When the FPGA boots, this module should be able to send a batch of
configuration writes to one or more I2C busses, without external help.
* After boot, it should go into a polling loop, reading out status
and making it available via a convenient dual-port-memory interface to
a host (local or network-based).
* A host (local or network-based) should be able to modify existing or
create new command strings to send to the I2C busses.
* Collect bus activity traces to let people diagnose bus behavior
* Be small enough to be ignored in the resource accounting of an SoC

## Design

Internally, the design uses a dual-port RAM (one quantum in 7-series is 4K x 8)
to hold:

* an instruction sequence, including data for I2C write commands
* results of I2C read commands
* output trace from an embedded logic analyzer

See below for more discussion of the sequence (program) that is held
in that first section of memory.

A simplified block diagram is in blocks.eps.
It is annotated, to possibly be useful as a top-level introduction to the code.
To edit that file, use xcircuit.  If you'd rather look at it as a PDF,
"make blocks.pdf".

Current synthesis result in Spartan-6 using ISE 14.7:
  203 LUT/FF pairs and 2 x 16K BRAM, 200 MHz

## Usage

The expected interface to the rest of your chip design is i2c_chunk.
This is a single-clock-domain design (input clk).

![symbol](i2c_chunk.svg)

Bus timing parameter tick_scale, default 6:
One I2C bit time is (clk period) * 14 * 2^(tick_scale).
With 125 MHz clock, that yields 7.168 uS, for a bus bit rate of 140 kHz.

Local bus ports:

* 12-bit lb_addr
* lb_write
* 8-bit lb_din
* 8-bit lb_dout

The 4 kByte local bus memory is subdivided into quarters:

*  0x000 - 0x3ff   program
*  0x400 - 0x7ff   logic analyzer
*  0x800 - 0xbff   results
*  0xc00 - 0xfff   result buffer in progress (not meant for host access)

Auxiliary control and status:

* input run_cmd
* input freeze
* output run_stat
* output updated
* output err_flag

Hardware tie-in:

* output scl
* output sda_drive
* input sda_sense
* output hw_config (Can be used to select between I2C busses)

When running, a typical instruction sequence will fill one half of the
output ping-pong buffer, and then request an atomic swap so that new data
is accessible from the host side (bf command, see below).
This buffer flip request is willfully ignored if the freeze bit
is set by the host.  This supports a guaranteed-self-consistent
readout paradigm that should be used by the host:

* Set freeze bit
* Read out buffer
* Clear freeze bit

The idea is that this operation will be quick compared to the polling
cycle, and is permitted to happen at any time.  This assumes there are
negligible consequences of dropping an occasional buffer of data;
new data will arrive shortly anyway.

The host can optimize this process somewhat by checking the updated bit,
and only reading data out when it is set.  As a side effect to setting
and clearing the freeze bit is to clear the updated status bit.

## Workstation requirements

Standard *nix tools, Icarus Verilog, gtkwave,
GhostScript.  At some point you'll also need chip-specific synthesis,
place, and route for the full chip that will instantiate this module.

To exercise some simple regression tests, just do "make".
To exercise the logic-analyzer part, "make a2trace_view".
Makefile targets can also give you waveform views of the internal states:
i2c_bit_view, i2c_prog_view, i2c_analyze_view, and i2c_chunk_view.

## Programming

There is some python code in here that acts as an assembler for
the instruction sequence that gets loaded into i2cbridge to control
the I2C operations.

Instruction encoding:
```
 3-bits opcode
 5-bits numeric parameter n
```
opcode
```
 000  oo   special
 001  rd   read
 010  wr   write
 011  wx   write followed by repeated start
 100  p1   pause (ticks are 8 bit times)
 101  p2   pause (ticks are 256 bit times)
 110  jp   jump
 111  sx   set result address
```
specials
```
 000 00000  zz  sleep
 000 00010  bf  result buffer flip
 000 00011  ta  trigger logic analyzer
 000 1xxxx  hw  hardware bus select/configure (includes reset?)
```
The jump command jumps to the address constructed as {n, 5'b0}, thus can
reach the whole 10-bit address space reach with granularity of 32 bytes.

wr and wx instructions are followed by n words of data.
A rd instruction is followed by only 1 data word (the device address);
the remaining n-1 words are all sent as high bits on the i2c bus, allowing
the data coming back from the slave to be read and posted to result memory.

The alert Makefile reader will observe that the instruction sequence fed to
the test bench is created by a python program, ramtest.py.  This program
includes a built-in assembler that encapsulates the instruction encoding
shown above.

# Other notes

The I2C czars would be unhappy that this code doesn't handle clock
stretching or multi-mastering.  So officially this should be called TWI
(two-wire interface) instead.  But it's intended for use with commonly
available I2C peripherals, including SFP modules, and none of the chips
I've encountered actually use those exotic features.

The dpram.v code is not identical to that in LBNL's code repo.
It is superficially compatible, and ought to be merged after more
discussion and testing.

# To do

* Synthesis-time setup of RAM contents
* Write more documentation
* Add more features to i2c_prog: skip if interrupt
* Add more features to analyzer: commands, reset, interrupt
* Wishbone bridge?
* Add meta-control path?

See design.txt for a longer story.
