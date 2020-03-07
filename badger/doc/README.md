# Figures

This directory holds diagrams that document various aspects of Packet Badger.
The Verilog source code refers to these as appropriate.
Some of them are also used by the README.md in the root directory.

All the .eps files here are created and editable by [xcircuit](http://opencircuitdesign.com/xcircuit/).
Rules in the associated Makefile convert them to the web-compatible SVG format.

### Block Diagram
![block diagram](rtefi.svg)

### Attachment of clients:
![client interface timing diagram](clients.svg)

### Memory gateway (localbus) timing:
![mem_gateway timing](mem_gateway.svg)

### Internal memory addressing:
![memory access diagram](memory.svg)

### Data path in construct.v:
![data path diagram](tx_path.svg)

### Design study for a precog upgrade
![timing diagram](precog_upg.svg)
