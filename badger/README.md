# Packet Badger

## Introduction

Packet Badger is a digital logic design, implemented on an FPGA, that
digs through Ethernet packets to construct a response.  Its intended
application is to let workstations and servers communicate with FPGA-based
instruments over UDP.  On its own, it provides ARP, ICMP echo, and UDP echo
services.  It has a (documented and tested) interface to add additional
UDP services that provide the application-useful data flow.

Packet Badger attaches to Ethernet using the GMII standard.  Adapter layers
inside the FPGA can let it connect to GMII, RGMII, SGMII, or MGT PHY hardware.
Mechanisms are provided to attach a software-based simulation of Packet Badger
to the computer's TUN/TAP subsystem (requires root access for setup),
or single clients to a UDP socket, permitting development of client software
and HDL without depending on the target hardware.

Packet Badger is written in portable, synthesizable Verilog.  When targeting
Xilinx 7-series chips, it occupies about 1000 LUTs and 1 RAMB18.

Packet Badger is designed to only respond promptly to packets, never initiate
traffic.  It is tuned for plug-in modules (one per UDP service port) that can
respond in a fixed number (parameterized) of clock cycles latency.  Examples
are given for such modules that:

* Gateway to an on-chip local bus (protocol [documentation](mem_gate.md))
* Give read/write access to an SPI Flash memory

Unlike logic designs that use a soft core to implement Ethernet/IP protocols,
it is capable of full-rate gigabit-per-second data transfer, and has a
relatively small footprint in the FPGA fabric and memory.

This design roughly parallels an earlier LBNL Ethernet fabric design
(PSPEPS), but with architectural bugs fixed.  If the Ethernet physical
link stays up, it will never drop a packet.

The architecture permits adding a MAC for a soft-core CPU, that could be
useful for low-bandwidth setup functions like DHCP or SCPI.  An initial
implementation is included.

The author asserts that its architecture will permit addition of strong
authentication to each packet, without adding (much) overhead in latency,
throughput, or hardware resources.  Efforts to demonstrate that are still
in a prototyping stage, and are not included here.

Only synthesizable code, programs (and their data) to generate synthesizable
code, and documentation are here in the base directory.  Files that implement
the extensive self-test capability, including test builds for hardware, are
squirreled away in the tests/ directory.  Projects that instantiate this
code are expected to accomplish the build step by including rules.mk.

## Block Diagram

[rtefi.eps](rtefi.eps)

## Functionality

Input packets are checked according to the following.
Failures are not reported, just dropped.

All packets:

* Source MAC is unicast, not multicast
* CRC32 OK
* Total GMII frame length (including Ethernet header and CRC32) <= 1536
* Minimum frame length _not_ checked

ARP request:

* EtherType 0x0806
* Hardware address space 1 (Ethernet)
* Protocol address space 0x0800 (Ethernet/IP)
* 6-byte hardware addresses, 4-byte protocol addresses
* Opcode 1 (request)
* _No_ checks on embedded source IP or MAC
* Dest IP matches our configuration
* _No_ checks on embedded dest MAC
* _No_ checks on Ethernet header dest MAC (normally broadcast)

IP:

* Dest MAC matches our configuration
* EtherType 0x0800
* IPv4
* No options
* IP total length fits within its GMII frame
* No fragmentation
* Non-zero TTL
* IP header checksum OK
* _No_ checks on source IP address
* Dest IP matches our configuration

ICMP echo request (depends on IP):

* IP Protocol 1
* ICMP type 8, code 0
* ICMP checksum OK

UDP (depends on IP):

* IP Protocol 17
* Source port >= 1024
* Dest port matches one of the clients (but not zero)
* Length fits within IP packet
* UDP checksum _not_ checked

If a reply is sent, it _always_ has its destination MAC transcribed
from the requesting packet's source MAC.  Likewise, the destination IP
is transcribed from the source IP (although this means different things
for ARP and IP), and the UDP destination port is transcribed from the
source port.

It is strongly recommended that UDP destination port numbers get configured
to be < 1024.

## Example "live" test run

Demonstrating both Packet Badger functionality, and the test framework's
ability to attach the simulation to the host's Ethernet subsystem.

In one shell session (Linux terminal), try:

    cd tests
    sudo tunctl -u $USER && sudo ifconfig tap0 192.168.7.1 up
    make tap_start

In another terminal, try the following to pull contents from `fake_config_romx.v`
through `mem_gateway.v` at IP address `192.168.7.4`, localbus UDP port 803:

    printf "sillyoneT\x1\x0\x0yyyyT\x1\x0\x1yyyyT\x1\x0\x2yyyyT\x1\x0\x3yyyy" | nc -q 1 -u 192.168.7.4 803 | hexdump -v -e '8/1 "%2.2x " "  "' -e '8/1 "%_p" "\n"'

Expected result:

    73 69 6c 6c 79 6f 6e 65  sillyone
    54 01 00 00 00 00 80 0a  T.......
    54 01 00 01 00 00 73 34  T.....s4
    54 01 00 02 00 00 b9 48  T......H
    54 01 00 03 00 00 d2 76  T......v

You can now interrupt (control-C) the simulation.  That process should
have left behind a rtefi_pipe.vcd file that can be viewed with gtkwave;
a pre-configured gtkwave pane can be brought up with "make rtefi_pipe_view".

## More Diagrams

### Memory addressing:
[memory.eps](memory.eps)

### Attachment of clients:
[clients.eps](clients.eps)

### Data path in construct.v:
[tx_path.eps](tx_path.eps)

## Other documentation

* Design notes: [rtefi_notes.txt](rtefi_notes.txt)
* Status: [status.md](status.md)
