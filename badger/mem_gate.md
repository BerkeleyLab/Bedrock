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

## Packet structure

LASS supports two types of packet structure. A simpler one, based on single-beat
transactions, and a more complex block-transfer structure where a single burst-transaction
is encoded more efficiently.

The basic packet structure consists of a 64-bit transaction ID, followed by one
or more single-beat transactions. Each transaction encodes a single read or write
bus cycle. This type of packet is organized as follows:
```
+--------+-------+---------+-----------------+ +-------+--------+--------------+
| TX ID  |  CMD  |  ADDR0  |      DATA0      | |  CMD  |  ADDR1 |    DATA1     |
+--------+-------+---------+-----------------+ +-------+--------+--------------+
   64b      8b       24b           32b             8b      24b        32b
```

The block-transfer packet structure also starts with a 64-bit transaction ID and
encodes a stream of either writes or reads to consecutive addresses, starting at
a given base address. This type of packets is organized as follows:
```
+--------+-------+---------+-------+---------+---------+ +---------+ +---------+
| TX ID  |  CMD  | REPCNT  |  CMD  |  ADDR0  |  DATA0  | |  DATA1  | |  DATA2  |
+--------+-------+---------+-------+---------+---------+ +---------+ +---------+
   64b      8b       24b       8b      24b       32b         32b         32b
```
The type of packet structure being used is indicated by appropriately setting the
operation (OP) field in the first 8-bit command (CMD) block. Whereas the basic
structure must simply set OP to 'Read' or 'Write', the block-transfer packet must
set OP in the first CMD block to 'Burst' and use the second CMD block to select
between 'Read' or 'Write'.

Note that packets utilizing the single-beat transaction structure may alternate
reads and writes throughout the packet, by setting each CMD block appropriately.
Packets utilizing the block-transfer structure, on the other hand, are locked to
either reads or writes throughout, as set in the second CMD block.

## Data encoding

For both packet structures, the bit-widths add up such that all transactions
start on a 32-bit boundary. Data encoding is big-endian, a.k.a. network byte order.

In order to preserve 32-bit boundaries, the CMD and repeat count (REPCNT) blocks
are oversized in relation to the information they convey.

The 8-bit CMD block carries a single 2-bit operation field (OP), according to the
following encoding:
```
+------+------+----------+
| RSVD |  OP  |   RSVD   |
+------+------+----------+
7     6 5    4 3        0
```
| OP [1:0] | Operation |
|  ------  |  ------   |
| 'b00     | Write     |
| 'b01     | Read      |
| 'b10     | Burst     |
| 'b11     | Reserved  |

N.B.: Reserved bits should be set to 0 by software. Failing to do this may result
in undefined behavior, since they may be defined in some future revision. One valid
response from the FPGA is therefore to drop packets that have unused bits set.

The 24-bit REPCNT block only uses 9 bits to encode the actual repetition count, as
shown below. Note that while the width of the COUNT field places an upper bound on
the number of data beats that can be transferred in a single packet, typical UDP
packet sizes place additional restrictions on this number. These limitations are
outlined in the next section.
```
+-------------+----------+
|    RSVD     |   COUNT  |
+-------------+----------+
24     6 5     8        0
```
| COUNT [8:0] | # Data Beats |
|    ------   |     ------    |
| 'h00        | Illegal       |
| 'h01        | 1             |
| 'h02        | 2             |
| 'hN         | N             |

## Practical considerations

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
is space for a maximum of 183 single-beat transactions per packet.

Likewise, it is possible to fill a packet with a block-transfer transaction with
364 data words, thus setting a practical limit on the values that can be used in
the REPCNT block.

Exceeding the Ethernet MTU will trigger fragmentation on the software side,
which both is theoretically undesirable, and practically not supported by
typical FPGA UDP implementations.

Driver software should have the maximum packet size easily configurable,
to be adaptable to changes in MTU or additional protocol layering.
An authentication layer could reduce the available packet size by 16 octets.

## Other considerations

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
Spartan-6 or 7-Series chips. [Comparison to EtherBone?]
