# Yet another I2C (really TWI) bridge/controller/interface

Larry Doolittle, LBNL, August 2018

## Primary goals

* When the FPGA boots, it should be able to send a batch of
configuration writes to one or more I2C busses, without external help.
* After boot, it should go into a polling loop, reading out status
and making it available via a convenient dual-port-memory interface to
a host (local or network-based).
* A host (local or network-based) should be able to modify existing or
create new command strings to send to the I2C busses.
* Collect bus activity traces to let people diagnose bus behavior
* Be small enough to be ignored in the resource accounting of an SoC

As of February 2020, it appears to meet all these goals.

## Usage

The expected interface to the rest of your chip design is i2c_chunk.
This is a single-clock-domain design (input clk).

![symbol](i2c_chunk.svg)

Parameter tick_scale controls the bus timing, default value is 6.
One I2C bit time is (clk period) * 14 * 2^(tick_scale).
With 125 MHz clock, that yields 7.168 uS, for a bus bit rate of 140 kHz.

Parameter initial_file allows loading a program at synthesis time.
Default value of "" (empty string) means no load; otherwise provide
a filename suitable for use with Verilog $readmemh().

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

See below for more discussion of the sequence (program) that is held
in that first section of memory.

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

The scl port should drive the SCL pin directly.  The SDA pin is open-collector
style, and requires three-state hardware that is not universally considered
part of synthesizable Verilog.  The sda_drive pin has the same polarity as
the final SDA pin, so a low value should cause pull-down (tri-state enable
with value 0).  The sda_sense port passes the logic value of the I/O pin back
to this module.

Using the hw_config output to select between multiple I2C busses is
possible (and has been hardware-tested) but complicates handling of the
scl and sda pins.  The value of hw_config is set by the hw instruction,
described below.

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
and only reading data out when it is set.  The updated flag is cleared
as a side effect of clearing the freeze bit.

Whether or not an initial program was set up at synthesis time with
initial_file, new programs can be tested as follows:

* de-assert run_cmd
* wait for run_stat to read back 0
* write a new program into addresses 0x000 - 0x3fff
* assert run_cmd

## Design

![block diagram](blocks.svg)

A simplified block diagram of i2c_chunk.v is shown above,
It is annotated, to possibly be useful as a top-level introduction to the code.
That svg file was converted from an xcircuit file blocks.eps.
If you'd rather look at it as a PDF, "make blocks.pdf".

Current synthesis result in Spartan-6 using ISE 14.7:
  197 LUT/FF pairs and 2 x 16K BRAM, compatible with clocks up to 200 MHz.
Extensively hardware-tested on Artix-7/Vivado at 125 MHz,
as part of a much larger design.

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
the I2C operations (see `assem.py`).

A low-level programming interface is provided by `class i2c_assem`
while a higher-level object-oriented interface is provided by the
`class I2CAssembler`.  The API of the latter is a superset of the
former with as few changes as possible to the common function set.
The higher-level interface attempts to catch common gotchas inherent
with the low-level interface as well as alternate functions for
working with explicit address values or address indices (multiples
of 32).  See `ramtest.py` for a demo of the low-level interface and
`demo_assem.py` for a demo of the high-level interface.  Also, see
the Makefile targets 'map.*' for the various flavours of register
memory maps that can be generated automatically.

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
 000 1xxxx  hw  hardware bus select/configure
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

# To do

* Better design of assembler: integrate readout decoder
* Write more and better documentation
* Add more features to i2c_prog: skip if interrupt
* Add more features to analyzer: commands, reset, interrupt
* Wishbone and/or AXI bridge?

See design.txt for a longer story.
