`timescale 1ns / 1ns
// First try to make an LCLS-2 beam pulser, 2014-11-17
// Closely related to common_hdl/ph_acc.v
// ena input allows use of a 188 MHz clock while the state logic
//   progresses at 94 MHz
// Nominal LCLS-2 configuration: phase_step=13, modulo=-1320, see beam_tb.v
// Beam pulses out last up to two cycles, have uniform integrated amplitude,
//   and the time between each pair of pulses (computed from the centroid of
//   each pulse) is correct (1320/13 cycles for the nominal configuration).
module beam(
	input clk,  // timespec 9.0 ns
	input ena,
	input reset,  // active high, synchronous with clk and ena
	output [11:0] pulse,
	input [11:0] phase_step, // external
	input [11:0] modulo,  // external
	// Initial phase value to align beam with individual cavities
	input [11:0] phase_init  // external
);

reg carry=0, carry1=0;
reg [11:0] phase=0, resid, pulse_r=0;
always @(posedge clk) if (ena) begin
	{carry, phase} <= reset ? {1'b0, phase_init} : ((carry ? modulo : 12'b0) + phase + phase_step);
	carry1 <= carry;
	resid <= phase_step - phase;
	pulse_r <= carry ? phase : carry1 ? resid : 0;
end
assign pulse = pulse_r;

endmodule
