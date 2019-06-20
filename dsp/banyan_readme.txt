Explanation for what banyan.v is, and why it's built like that.
Larry Doolittle, LBNL, May 2016

Consider an abstract set of N data sources (e.g., ADCs) and N data sinks
(e.g., memory), with data routing hardware in between:

        --------
in1 -->|        |--> out1
       |        |
in2 -->|        |--> out2
       | router |
in3 -->|        |--> out3
       |        |
in4 -->|        |--> out4
        --------

The goal is to take various subsets of the inputs, and route them to
outputs for storage.  The storage at each sink is finite, and we'd like to
be able to take as long a time-series as possible.  If we only want to record
data from a 1/K subset of the inputs, after filling up 1/K of the outputs,
the router changes state and sends the data to a different set of outputs.
Thus the length of time-series data that can be stored is multiplied by K.

Suppose the router is built from a moderate number of 2-in 1-out switches,
and hardware is "expensive".  A full crossbar router, capable of selecting
each output from any input, would take N*(N-1) switches, and is wasteful.
As long as the mapping is documented, we don't really care into _which_ output
channels each input is stored.  So for K=1, only one mapping needs to be
supported.

When N is a power of 2, a hardware topology that smells like it has a useful
balance between flexibility and cost looks like this:

           -      ------------
in1 ------| |--->|            |--> out1
       \ / -     | N/2 router |
in2 ----X-| |--->|            |--> out2
       X X -      ------------
in3 ----X-| |--->|            |--> out3
       / \ -     | N/2 router |
in4 ------| |--->|            |--> out4
           -      ------------
        N 2-way
       data muxes

[Pardon the crude ASCII art; a much better rendition is in banyan_topo.eps]
The cost of this design is N*log2(N), and the structure is reminiscent
of an FFT, or the edges of an N-dimensional cube.  My specific need has
N=8, using 24 2-way switches total.  Switches are controlled in pairs,
where a pair is used to swap two channels; the above diagram is supposed
to show a configurable swap of in1 with in3, and of in2 with in4, where
the two swaps are independently controlled.

I need this router to:
- route any single input to each of the 8 outputs in turn
- route any two inputs to 4 outputs in turn, spanning all eight outputs
- route any four inputs to 2 outputs in turn, spanning all eight outputs
- route all 8 inputs 1:1 to the eight outputs
The above routing network does in fact have the desired capability.

If a router with this capability can be built with fewer than N*log2(N)
switches, I'd like to know about it.

I seem to have reinvented the Banyan switch topology,
  https://en.wikipedia.org/wiki/Banyan_switch
I have yet to find a clear and a concrete definition of what qualifies
as a Banyan switch, and certainly not any instructions on how to control
the multiplexers in the manner needed here.

What is required next is a clearly defined way to control the 12 swap-boxes,
based on the channel selection and state of the filling sequence.  Also, each
output channel needs to be told whether or not to store its input.  This is
mostly a hardware design, so at some point we need binary representations of
everything.  But software will be used to pull data out of the memories,
so the mapping expression also needs to be software-friendly.

Represent the channel selection configuration with an 8-bit mask of
which channels to look at.  Only 1+70+28+8 = 107 of 256 possible masks
are valid, since it's invalid to have 0, 3, 5, 6, or 7 bits set.
The time state is (at most) 3 bits.  Actually useful configuration inputs:
 8 parallel  :   1 combination    x  1 time state
 4 parallel  :  70 combinations   x  2 time states
 2 parallel  :  28 combinations   x  4 time states
 1 at a time :   8 possibilities  x  8 time states
A separate problem will be how to make a user interface to define
the active channels.

Recursively layer the control logic, much like the routing logic.
Each layer can have one of two functions, which I label "balancing"
and "dealing".  Balancing happens in the early layer(s), shifting data
to keep the number of active channels to the two recursive sublayers
equal (balanced).  When the number of active channels in a layer is
reduced to one, it means that single data stream has to be routed to
a set of outputs in time sequence (dealing, as in playing cards).

Given an N-bit mask input, and a log2(N) bit time state: first, decide
if we are in balancing mode (more than one bit set in the mask) or
dealing mode (only one bit set).  Balancing: take the even number
of bits set in the mask and apply flips such that an equal number go
to the top and bottom sub-router.  Dealing: route the one bit input
to the top or bottom sub-router according to the msb of the time state.

Balancing mode logic for one layer requires computation of N/2 mux control
lines.  The simplest describable logic is structured like a carry chain,
and can probably even map into an FPGA's carry chain.  The propagating bit
carries the semantics "out of the possible swaps considered so far, one more
data path has been routed to the upper sub-router than the lower sub-router".
This imbalance bit starts at 0.  Passing through one swap-pair's logic, it
gets XORed with the XOR of the two mask bits.  Each swap control output is
imbalance_in ? ~mask_upper & mask_lower : mask_upper & ~mask_lower.

Coding the channel mapping function in C or python seems strange at least.
Do a "make banyan_tb && vvp banyan_tb +trace +squelch" to see what it has
to be consistent with.  First column is the channel selection mask, second
column is the time state.  My first attempt at a python version is in
banyan_ch_find.py.  "make banyan_crosscheck" to exercise it -- it does seem to
get the right answers, and I think its output is friendly enough for use.
