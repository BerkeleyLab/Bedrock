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

LASS packets are composed of a 64-bit transaction ID followed by a string of
consecutive transactions.

Two types of transactions are supported. A single-beat transaction where single read
or write bus cycles are encoded, and a more complex, block-transfer based, where a
burst of reads and writes to consecutive addresses are encoded in a more efficient
manner.

A single-beat transaction is encoded in 64 bits and is comprised of command, address
and data fields. The diagram below shows how this transaction type can be used to
form a simple packet containing two single-beat read or write transactions.

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Transaction ID [31:0]                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Transaction ID [63:32]                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Command    |                    Address 0                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Data 0                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Command    |                    Address 1                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Data 1                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

**NOTE:** This and all other packet diagrams follow the convention used in RFC-791,
whereby bytes are shown as they are sent 'on the wire', i.e., network-byte-order.

The packet space consumed by a block-transfer transaction depends on how many data
beats are being read or written. At a minimum, this type of transaction can be encoded
in 96 bits and adds an additional command and a repetition-count field to the
single-beat transaction described previously. The additional command field is used
to signal that the transaction being decoded is of type 'burst'. The following diagram
depicts the structure of a packet containing a single block-transfer transaction where
two beats of data are either read or written.
```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Transaction ID [31:0]                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Transaction ID [63:32]                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Cmd (Burst)  |                Repetition Count               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Command    |                    Address 0                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Data 0                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Data 1                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

Note that each transmitted packet can string together any combination of these two
transaction types, provided the maximum packet length is not exceeded (see section
on practical considerations). This can be useful when, e.g., a long array and the
status register indicating its validity must both be read, and splitting the operation
into two packets is not desirable. The diagram below shows how such a packet could
be structured.

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Transaction ID [31:0]                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Transaction ID [63:32]                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Command    |                    Address 0                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Data 0                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Cmd (Burst)  |                Repetition Count               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Command    |                    Address 1                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Data 1                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Data 2                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## Data encoding

For both transaction types, the bit-widths add up such that all transactions
start on a 32-bit boundary. Data encoding is big-endian, a.k.a. network byte order.

In order to preserve 32-bit boundaries, the Command and Repetition Count fields
are oversized in relation to the information they convey.

The 8-bit Command field carries a single 2-bit operation sub-field (OP), according to the
following encoding:
```
 0  1  2  3  4  5  6  7
+--+--+--+--+--+--+--+--+
| RSV | OP  |    RSV    |
+--+--+--+--+--+--+--+--+

OP [1:0]:
   2'b00 - Write
   2'b01 - Read
   2'b10 - Burst
   2'b11 - Reserved
```

N.B.: Reserved bits should be set to 0 by software. Failing to do this may result
in undefined behavior, since they may be defined in some future revision. One valid
response from the FPGA is therefore to drop packets that have unused bits set.

The 24-bit Repetition Count field only uses 9 bits to encode the actual repetition count, as
shown below. Note that while the width of the COUNT sub-field places an upper bound on
the number of data beats that can be transferred in a single packet, typical UDP
packet sizes place additional restrictions on this number. These limitations are
outlined in the next section.
```
 0                   1                   2
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|            Reserved           |     COUNT     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

COUNT [8:0]:
   9'h0 - Illegal
   9'h1 - 1 Beat
   9'h2 - 2 Beats
   ...
   9'hN - N Beats

```

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
the Repetition Count block.

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
