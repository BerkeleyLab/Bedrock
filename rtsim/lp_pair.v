`timescale 1ns / 1ns

// Time-interleaved pair of low-pass filters
// Larry Doolittle, LBNL, May 2014
// Upper six drive bits in drive2 are for short-pulse
// contributions from the beam; don't use them CW or this accumulator
// will overflow.  To avoid instant overflows with such wide input,
// shift should be > 6.
module lp_pair(
	input clk,
	input signed [17:0] drive,
	input signed [23:0] drive2,
	(* external *)
	input signed [17:0] bw,  // external
	output signed [17:0] res
);

parameter shift=18;  // maximum bandwidth is f_clk/2/2^shift/(2*pi)
// e.g., with f_clk=188.6 MHz, shift=18, max BW is 57.2 Hz.

// Note that as the bandwidth is turned down from that maximum,
// so too should the signal level of the drive.  We don't have
// overflow detection programmed in here.

// 1/(1+(1-a)*z^{-2}) for small a behaves a lot like 1/(1+(1-a)*z^{-1})

// Scalar multiply field by the desired bandwidth, sets decay time
reg signed [17+shift:0] state=0, sum1=0;
reg signed [35:0] decay1=0;
wire signed [17:0] decay1s = decay1[34:17];
reg signed [17:0] decay2=0, decay3=0;
wire signed [18:0] diff = drive - $signed(state[17+shift:shift]);
always @(posedge clk) begin
	decay1 <= $signed(diff[18:1]) * bw;
	decay2 <= decay1s;
	decay3 <= decay2;
	sum1 <= state + drive2;
	state <= sum1 + decay3;
end

assign res = state[17+shift:shift];

endmodule
