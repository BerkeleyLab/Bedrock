`timescale 1ns / 1ns

module cav_freq(
	input clk,
	input signed [17:0] fine,
	// getting the following control into the address map is the
	// whole point of this module:
	(* external *)
	input signed [27:0] coarse_freq, // external
	output signed [27:0] out
);

// valid range of df_scale is 0 to 9, but one has to be increasingly
// concerned about overflow.  The Pro tip about the range of coarse
// frequency in cav_elec.v is implicitly sensitive to df_scale.
parameter df_scale=0;

reg signed [29:0] out_r=0;
always @(posedge clk) out_r <= (fine<<<df_scale) + (coarse_freq<<<2) + 2;
assign out = out_r[29:2];

endmodule
