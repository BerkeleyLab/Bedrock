`timescale 1ns / 1ns
module adc_em(
	input clk,
	input strobe,
	input signed [17:0] in,
	input [12:0] rnd,  // randomness
	(* external *)
	input signed [9:0] offset,  // external
	output signed [15:0] adc
);

parameter del=1;

// We wish to emulate a LTC2175-like ADC, 14-bit with 73.0 dB SNR.
// 14-bit full-scale sine wave has rms value 2^13/sqrt(2) = 5793.
// So the noise level is -73.0 dB from there, or 1.30 bits rms.
// One random bit flickering has mean 1/2 and variance 1/4, so to
// emulate a variance of 1.30^2, we need 6.76 (really 20.3) such bits.

// Adding together 6 bits would give a range of +/- 3 quanta, and
// and an rms of 1.22, for a peak/rms ratio of 2.45, pretty pathetic.

// Adding together 26 bits would give a range of +/- 13 quanta,
// and an rms of 2.55, for a peak/rms ratio of 5.10, plausible.
// Divide that result by two to get the desired rms of 1.27.

// Since this module is designed to be double-clocked, take in
// just 13 bits of randomness per cycle.

// The nominal ADC at the moment is 14-bits, so when we're done,
// pad to the right with two more bits, to fit the future-proof
// 16-bit interface.

// Get random bits from TT800 or equivalent, combine them here to
// get the required Additive White Gaussian Noise.  By construction,
// when each random input bit is fair, the mean of awgn is zero.
// Also, if the PRNG stalls, the AWGN term goes immediately to zero.
wire [12:0] p = rnd;
reg [3:0] bit_cnt=0, bit_cnt_d=0;
reg signed [4:0] awgn=0;
always @(posedge clk) begin
	bit_cnt <= p[0]+p[1]+p[2]+p[3]+p[4]+p[5]+p[6]+p[7]+p[8]+p[9]+p[10]+p[11]+p[12];
	bit_cnt_d <= bit_cnt;
	awgn <= bit_cnt - bit_cnt_d;
end

// Combine "real" voltage, AWGN, and offset
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
reg signed [18:0] sum=0;
always @(posedge clk) sum <= in + (awgn <<< 3) + offset;
wire signed [14:0] sum_trunc = sum[18:4];
reg signed [13:0] sat=0;
always @(posedge clk) sat <= `SAT(sum_trunc,14,13);

// Adjustable delay
wire signed [13:0] dval;
reg_delay #(.dw(14), .len(del))
	dd(.clk(clk), .reset(1'b0), .gate(strobe), .din(sat), .dout(dval));

assign adc = {dval,2'b0};

endmodule
