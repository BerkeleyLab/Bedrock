// Note:
// this model is for 1 device per wire only
// it does not respond to the `normal search` (0xF0) or
// `conditional search` (0xEC) commands

// ds1822.v
// Behavioral model of a Dallas 1-Wire[TM] device, e.g., a DS1822 or DS2401
// Larry Doolittle, LBNL

// Derived from ds1822.v found in
// llc-suite Copyright (c) 2004, 2005, The Regents of the University of
// California, through Lawrence Berkeley National Laboratory (subject
// to receipt of any required approvals from the U.S. Dept. of Energy).

// More or less complete, although a little verbose.
// Might want to use some min/typ/max features of delays?
// This module handles the bit timing of the 1-Wire interface, and
// instantiates ds1822_state.v to handle the command/response layer.
// So this module is (I hope) completely part-independent.

// Pulse widths from DS2401 data sheet:
//  Initialization Procedure "reset and presence pulses" Figure 5
//    t_RSTL   480 us to infinity
//    t_RSTH   480 us to infinity (includes recovery time)
//    t_PDH     15 us to  60 us
//    t_PDL     60 us to 240 us
//  Read/Write Timing Diagram  Figure 6
//   Write-one Time Slot
//    t_SLOT    60 us to 120 us
//    t_LOW1     1 us to  15 us
//    t_REC      1 us to infinity
//        (so the pin is sampled and the action happens up to 120 us
//         after the falling edge, but the next falling edge doesn't
//         have to happen anytime soon)
//   Write-zero Time Slot
//    t_SLOT    60 us to 120 us
//    t_LOWD    60 us to t_SLOT
//   Read-data Time Slot
//    t_SLOT    60 us to 120 us
//    t_LOWR     1 us to  15 us
//    t_RELEASE  0    to  45 us
//    t_RDV     15 us

`timescale 1ns / 1ns

module ds1822(pin);
inout pin;

// XXX How do I give $random() a random seed?
integer last_fall, width;
reg in_data, smclk, reset;
wire out_data;
reg out_recent;
reg drive;
assign pin = drive ? 1'b0 : 1'bz;

parameter rom = 64'hbe000008e52f8e01;  // Actual data from a DS2401

(* ivl_synthesis_off *)
initial begin
	reset=0;
	last_fall=0;
	out_recent=0;
	drive=0;
end

parameter debug=0;

ds1822_state #(.rom(rom), .debug(debug)) ds1822_state(
	.reset(reset), .clk(smclk),
	.in_data(in_data), .out_data(out_data));

(* ivl_synthesis_off *)
always begin
	@(negedge pin);
	if (pin !== 1'b0)
		$display($time, " Error: invalid 1-Wire pin state ", pin);
	if (debug) $display($time, " found falling edge");
	last_fall = $time;
	smclk = 0;
	out_recent = out_data;
	fork
		if (out_recent == 1'b0) begin
			if (debug) $display("sending a zero bit");
			drive=1;
			#30000;  // range: 15000 to 60000?
			drive=0;
		end
		@(posedge pin);
	join
	if (pin !== 1'b1)
		$display($time, " Error: invalid 1-Wire pin state ", pin);
	width = $time-last_fall;
	if (debug) $display($time, " found rising edge, pulse width %d", width);
	in_data = 1'bx;
	if (width < 1000) begin
		$display("Error: pulse too short");
	end else if (width < 15000) begin
		if (debug) $display("write 1 pulse recognized");
		in_data=1;
	end else if (width < 60000) begin
		if (out_recent == 1'b0) begin
			if (debug) $display("I sent this zero pulse");
			in_data=1'b0;
		end else begin
			in_data=$random;
			$display("Error: ambiguous data, choosing %b", in_data);
		end
	end else if (width < 120000) begin
		if (debug) $display("write 0 pulse recognized");
		in_data=0;
	end else if (width < 480000) begin
		$display("Error: ambiguous data");
	end else begin
		$display("reset pulse recognized");
		reset = 1;
		// send presence pulse
		#16000;  // up to 60000
		drive = 1;
		#60000;  // up to 240000
		drive = 0;
		#404000; // keep from retriggering
		reset = 0;
	end
	if (in_data !== 1'bx) smclk = 1;
end
endmodule
