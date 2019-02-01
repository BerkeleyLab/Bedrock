# Packet Badger Status / Progress

* 2018-11-02:  Input scanner (scanner.v) can properly detect
  Ethernet, ARP, IP, ICMP, and UDP.  Makefile includes useful regression tests.
* 2018-11-13:  Simulation constructs working ARP and ICMP echo
  (ping) replies, verified with Linux tap interface.
* 2018-11-15:  Simulation (Linux tap) also gives UDP echo.
* 2018-11-18:  Hardware (SP605) responds to ARP and ICMP echo.
* 2018-11-20:  ARP, ICMP echo, and UDP all work reliably with tap
  using either Icarus or Verilator, and on SP605.
* 2018-11-23:  Responds only to configured set of UDP ports
* 2018-11-24:  Multiplexes between (trivial) UDP port sources
* 2018-11-28:  Documented, tested, and used client interface
* 2018-12-05:  Working mem_gateway, with regression test, confirmed on SP605
* 2018-12-10:  Fixed dropped-packets problem, tested with > 10^8 packets
* 2018-12-20:  Demonstrated functional on AC701/RGMII, synthesizing with XST
* 2018-12-21:  Demonstrated functional on AC701 when synthesizing with Vivado
* 2019-01-15:  Merged into bedrock

Synthesized by XST 14.7 for Spartan-6:

| **module**         |**LUTs**|**RAMB16**|
|:-------------------:|:-----:|:--------:|
|  scanner.v          |  273  |   |
|  construct.v        |  192  |   |
|  xformer.v          |   93  |   |
|  ethernet_crc_add.v |   94  |   |
|  udp_port_cam_v     |   31  |   |
|  rtefi_blob.v       |  748  | 1 |
|  sp605_gmii_test.v  | 1015  | 1 |

This Verilog code is intentionally portable and standards-based.
It has been tested using:
* verilator 3.900 (stock Debian stretch)
* verilator 4.008 (git from December 2018)
* iverilog 10.1 (stock Debian stretch)
* iverilog 11.0 (git from December 2018)
* Xilinx XST 14.7
* Xilinx Vivado 2015.3, 2017.4

All the .eps files here are created with and editable by xcircuit.

Files in tests/sp605/, tests/ac701/, and tests/kc705/ are only here temporarily;
eventually they should be constructed by the LBNL/ATG project infrastructure.

Next steps, loose but plausible order:
* Refactor udp-vpi.c to enable Verilator version of these tests
* Rename modules, signals, and project
* Create an instantiation template along with rtefi_blob.v
* Update documentation
* Analyze, test, and document limits on p_offset
* Better force or test that all GMII signals are latched in IOBs
* Set up CI server and pipeline with real FPGA
* Do something with GMII_RX_ER, test
* Decrement TTL as part of echo loop mitigation strategy?
* Consider dropping UDP packets with zero data length
* UDP Rx checksum?
* Add SPI clients
* Find help to exercise this on an Altera board
* Increase minimum number of 0x55 in Tx preamble
* Hook to allow use of TAP device other than tap0
* Expand testing, include corner cases, include short UDP packets, zero TTL
* Add monitoring hooks, like packet, byte, and error counts
* Add authentication option
* Research and integrate soft-core MAC
* Refactor and rewrite for clarity and reduced LUT count
