# Lightweight Address Space Serialization

LASS is an encoding of reads and writes to a traditional VME-like address space.
It is designed for transport over UDP, and has a coordinated set of features
that make it useful for data exchange between a commodity computer master and
an FPGA slave, with high throughput and controlled latency.

LASS is agnostic as to the details of the bus that is driven; it is suitable
for use with AXI, Wishbone, or the minimalist localbus in use by LBNL ATG.
The underlying bus configuration is fixed at 32 bits data, 24 bits of
word-address.  Byte access is not supported.  Of course, fewer address bits
and narrower data words can be accommodated with padding.

The basic packet structure looks like this:

* 64-bit ID
* transaction
* .
* .
* transaction

At its simplest, a transaction encodes a read or write bus cycle as

* 8-bit command (read or write)
* 24-bit address
* 32-bit data

A slightly more complex block-transfer form can also be supported

* 8-bit command (set repeat count)
* 24-bit repeat count (only 9 bits used)
* 8-bit command (read or write)
* 24-bit address
* 32-bit data
* .
* .
* 32-bit data

The bit-widths add up such that all transactions start on a 32-bit boundary.
Data encoding is big-endian, a.k.a. network byte order.

A key design element of this protocol is that every reply packet has
the same structure and length as the corresponding request packet.
Read requests put padding in the place where results will be returned;
replies to write requests echo the data that was written.
This balance naturally avoids overloading the reply channel, at least
in the common case of wire or fiber Ethernet deployments, because they
are full-duplex with symmetric bandwidth.
In this context, the processing logic embedded in the FPGA
can guarantee it will reply to every request.

The 64-bit ID can be any value chosen by the host, and will simply be echoed
by the FPGA.  This gives the software an easy mechanism to match up received
packets with outstanding requests.

In a typical Ethernet environment with 1500 MTU, UDP packets can have a
maximum payload size of 1472 octets.  Accounting for the 64-bit ID, there
is space for a maximum of 183 simple transactions per packet; it is also
possible to fill a packet with a single transaction with 364 data words.
Exceeding the Ethernet MTU will trigger fragmentation on the software side,
which both is theoretically undesirable, and practically not supported by
typical FPGA UDP implementations.
Driver software should have the maximum packet size easily configurable,
to be adaptable to changes in MTU or additional protocol layering.
An authentication layer could reduce the available packet size by 16 octets.

The 8-bit command word is encoded as

* 2 unused
* 2 function
* 4 unused

Unused bits should be set to 0 by software.
Unused bits that are set should be considered to have undefined behavior,
since they may be defined in some future revision.  One valid response from
the FPGA is therefore to drop packets that have unused bits set.

2-bit function codes:

* 0 - write
* 1 - read
* 2 - set repeat count
* 3 - reserved

A subset of LASS, without the repeat-count feature, has been used at LBNL
since about 2010.  Its FPGA-side implementation was rewritten in 2018
(Packet Badger) to operate properly on high-traffic networks.
This new version gives stronger real-time guarantees, and responds correctly
to "simultaneous" requests from multiple hosts/masters.

This feature set is extremely similar to EtherBone, sharing much of the
motivation and boundary conditions.  LASS is a bit more granular, is limited
to 24-bit addresses instead of 32, and is not specialized for Wishbone.
It would be interesting if someone rewrote or ported the EtherBone code
base/protocol as a plug-in to Packet Badger.

It's relatively easy to attach a simulated LASS FPGA-end to a real UDP port,
to exercise the combination of software and (virtual) hardware for debugging.
Packet Badger includes two demos of this setup, one using Verilator and one
using Icarus Verilog.

LASS as implemented on Packet Badger (along with other features like ARP and
ICMP echo, for attachment to a GMII PHY) occupies about 1100 LUTs of Xilinx
Spartan-6 or 7-Series chips.  Comparison to EtherBone?
