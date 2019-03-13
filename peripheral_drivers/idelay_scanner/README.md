# idelay_scanner

This directory contains a scanner, written in portable and synthesizable
Verilog, for finding the centers of a multi-lane
[eye pattern](https://en.wikipedia.org/wiki/Eye_pattern) coming from an ADC.
Tested and used in production on LBNL's Zest board with its AD9653 ADC.

Details are documented in the comments at the top of
[idelay_scanner.v](idelay_scanner.v).
This directory contains careful regression tests based on measurements
captured from real hardware.
