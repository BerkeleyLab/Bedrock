// ds1822_state.v
// Behavioral model of a Dallas 1-Wire[TM] device, e.g., a DS1822 or DS2401
// $Id$
// Larry Doolittle, LBNL
//
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

// This module is the command/response layer, and currently only handles
// reset, the Read ROM command, and the Skip ROM/Read Scratchpad command
// pair.  It might be interesting to add other commands, like Search ROM
// and Match ROM.
//
// This model responds to both 0x0f and 0x33 variants of the "Read ROM"
// command, like a DS2401.  A real DS1822 only responds to an 0x33.
//
// Instantiated from ds1822.v, that handles the bit timing of the 1-Wire
// interface.

// Curiously, this module is pretty much synthesizable, except for the
// $display()s.  That isn't its purpose, though.

`timescale 1ns / 1ns

module ds1822_state(
	input clk,
	input reset,
	input in_data,
	output reg out_data
);
parameter debug=0;

// out_data should idle at 1 when not actively transmitting
(* ivl_synthesis_off *)
initial out_data=1'b1;

integer cycle;   // invalid until reset provided
reg [7:0] command;  // value received
reg [7:0] command2; // second byte received (e.g., after a "Skip ROM" command)

// I'll make this a parameter, so I can simulate two at once.
parameter rom = 64'hbe000008e52f8e01;  // Actual data from a DS2401

parameter scratchpad = 72'h551009ff7f464b01d7;  // Actual data from a DS1822
// temperature = 29.44 degrees C

(* ivl_synthesis_off *)
always @(posedge clk or posedge reset) if (reset) begin
	$display("ds1822_state reset");
	cycle=0;
end else begin
	cycle=cycle+1;
	if (cycle <= 8)
		command = {in_data,command[7:1]};
	if (cycle == 8)
		$display("ds1822 command word %x", command);
	if (cycle <= 16)
		command2 = {in_data,command2[7:1]};
	if (cycle == 16)
		$display("ds1822 command2 word %x", command2);
	if (cycle >= 8 && cycle < 72 &&
		(command == 8'h33) | (command == 8'h0f))  begin // Read ROM
		out_data = rom[cycle-8];
	end else if (cycle >= 16 && cycle < 88 &&
		(command == 8'hcc) && (command2 == 8'hbe)) begin // Read Scratchpad
		out_data = scratchpad[cycle-16];
	end else begin
		out_data = 1'b1;  // non-responsive idle
	end
	if (debug) $display("ds1822_state clocked, in_data=%b, cycle=%d, out_data=%b",
		in_data, cycle, out_data);
end
endmodule
