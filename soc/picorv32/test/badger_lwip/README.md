# badger_lwip

Demonstrates the badger MAC with the `Lightweight TCP/IP stack` (lwIP).
Verilator is used to build an emulator which connects to the real world through a virtual TAP network interface.

# Instructions

Clone the master branch of lwIP ...

```bash
git clone https://git.savannah.nongnu.org/git/lwip.git
```

Set `LWIPDIR` in the Makefile to the src sub-directory of lwIP ...

```bash
LWIPDIR = <xxx>/lwip/src
```

### Setup the tap interface

```bash
sudo tunctl -u $USER
sudo ip addr add dev tap0 192.168.7.1/24
sudo ip link set dev tap0 up
```

### Run it
  * run the code with `make all` or `make badger_lwip.vcd` to debug hardware
  * lwIP sends a UDP packet to 192.168.7.1:1234, receive it with `nc -u -l -p 1234`
  * lwIP runs a web-server on port 80 to demonstrate TCP,
    open http://192.168.7.13/ in a web-browser
  * debug message settings and lwip configuration are in liblwip/lwipopts.h
  * to demonstrate DHCP, uncomment `dhcp_start(&netif);` and run a DHCP server
    on the local TAP0 network

### (Bridging)[https://wiki.archlinux.org/index.php/Network_bridge] tap0
A bridge is like a virtual network switch, connecting two or more links together (here tap0 and eth0). This allows the Verilog simulation to access the Internet.

```bash
sudo ip link add name br0 type bridge
sudo ip link set br0 up
sudo ip link set tap0 master br0
sudo ip link set eth0 master br0
```
