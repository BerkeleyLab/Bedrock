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
to the machine's TUN/TAP subsystem, or single clients to a UDP socket,
permitting development of client software and HDL without depending on
the target hardware.

Packet Badger is written in portable, synthesizable Verilog.  When targeting
Xilinx 7-series chips, it occupies about 1000 LUTs and 1 RAMB18.

Packet Badger is designed to only respond to packets, never initiate traffic.
Unlike logic designs that use a soft core to implement Ethernet/IP protocols,
it is capable of full-rate gigabit-per-second data transfer.
This design roughly parallels an earlier LBNL Ethernet fabric design
(PSPEPS), but with architectural bugs fixed.  If the Ethernet physical
link stays up, it will never drop a packet.

The authors assert that its architecture will permit adding a MAC for a
soft-core CPU, that could be useful for low-bandwidth setup functions like
DHCP or SCPI, but work has not started on that feature.

The authors also assert that its architecture will permit addition of strong
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

## Other documentation

* Design notes: [rtefi_notes.txt](rtefi_notes.txt)
* Status: [status.md](status.md)
* Memory addressing: [memory.eps](memory.eps)
* Data path in construct.v: [tx_path.eps](tx_path.eps)
* Attachment of clients: [clients.eps](clients.eps)
