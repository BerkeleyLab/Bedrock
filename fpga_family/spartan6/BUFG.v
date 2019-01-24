// BUFG.v
// BUFG simulation, also suitable as a synthesis aid with Icarus Verilog
// $Id$
// Larry Doolittle, LBNL

// llc-suite Copyright (c) 2004, The Regents of the University of
// California, through Lawrence Berkeley National Laboratory (subject
// to receipt of any required approvals from the U.S. Dept. of Energy).
// All rights reserved.

// Your use of this software is pursuant to a "BSD-style" open
// source license agreement, the text of which is in license.txt
// (md5sum a1e0e81c78f6eba050b0e96996f49fd5) that should accompany
// this file.  If the license agreement is not there, or if you
// have questions about the license, please contact Berkeley Lab's
// Technology Transfer Department at TTD@lbl.gov referring to
// "llc-suite (LBNL Ref CR-1988)"

`timescale 1ns / 1ns

(* ivl_synthesis_cell *)
module BUFG( output O, input I);
	buf B1(O, I);
endmodule
