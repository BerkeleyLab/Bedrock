`timescale 1ns / 1ns
// Multiplier-free half-band filter and decimator.
// See http://recycle.lbl.gov/~ldoolitt/halfband/

// This is an FIR filter
//   https://en.wikipedia.org/wiki/Finite_impulse_response
// with 7 non-zero taps, categorized as an order-3 half-band filter.
// The taps are
//   2  0  -9  0  39  64  39  0  -9  0  2

// The filter has a nominal low-frequency gain of unity.  But since
// the gain peaks at +0.074 dB (at an input frequency of 0.12 of the input
// sample rate), the output can clip.  The module correctly saturates
// its arithmetic.

// This filter is linear-phase (note the symmetric tap coefficients),
// with an essential DSP group delay of 5 samples.
// Additional pipeline delay is added by the implementation; see below.

// The input can consist of a fixed (set by the parameter len at
// build-time) number of interleaved signal data streams.
// The half-band filter is applied to each stream independently.

// half_filt() can accept 20-bit data at the full clock rate.
// The output stream is decimated by two; blocks of len cycles of 20-bit
// output data are interleaved with len silent cycles.  The input data
// and ing control are pipelined four cycles before getting to the output.

// There are no restrictions on the ing pattern.  The len-way
// interleaving of the input data ignores cycles with ing low.

// Synthesizes to 251 slices at 116 MHz in XC3Sxxx-4 using XST-8.2i

module half_filt(
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input signed [19:0] ind,  // Input data
	input ing,  // Active high gate marking input data as valid
	output signed [19:0] outd,  // Output data
	output outg,  // Active high gate marking output data as valid
	input reset  // manually reset counter
);

parameter len = 4;  // number of interleaved data streams
wire signed [19:0] d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10;

assign d0 = ind;
reg_delay #(.dw(20),.len(len)) h0(clk, 1'b0, ing, d0, d1);
reg_delay #(.dw(20),.len(len)) h1(clk, 1'b0, ing, d1, d2);
reg_delay #(.dw(20),.len(len)) h2(clk, 1'b0, ing, d2, d3);
reg_delay #(.dw(20),.len(len)) h3(clk, 1'b0, ing, d3, d4);
reg_delay #(.dw(20),.len(len)) h4(clk, 1'b0, ing, d4, d5);
reg_delay #(.dw(20),.len(len)) h5(clk, 1'b0, ing, d5, d6);
reg_delay #(.dw(20),.len(len)) h6(clk, 1'b0, ing, d6, d7);
reg_delay #(.dw(20),.len(len)) h7(clk, 1'b0, ing, d7, d8);
reg_delay #(.dw(20),.len(len)) h8(clk, 1'b0, ing, d8, d9);
reg_delay #(.dw(20),.len(len)) h9(clk, 1'b0, ing, d9, d10);

reg signed [20:0] s1=0, s2=0, s3=0, s4=0;
reg sg=0;
always @(posedge clk) begin
	if (reset) begin
		sg <= 0;
	end else begin
		sg <= ing;
	end
	s1 <= d0 + d10;
	s2 <= d2 + d8;
	s3 <= d4 + d6;
	s4 <= d5 + 0; // {d5[19],d5};
end

// FIR filter coefficients:
// 2*(1/32 0 -1/8-1/64 0 1/2+1/8-1/64 1 1/2+1/8-1/64 0 -1/8-1/64 0 1/32)/4
// see lowp3.m

reg signed [21:0] a1=0, a2=0, a3=0, a4=0;
reg ag=0;
always @(posedge clk) begin
	if (reset) begin
		ag <= 0;
	end else begin
		ag <= sg;
	end
`ifdef TRUST_VERILOG_DIVISION
	a1 <= s1/16 + 0;
	a2 <= s2/4 + s2/32;
	a3 <= s3/4 - s3/32;
	a4 <= s3 + 2*s4;
`else
	a1 <= {{5{s1[20]}},s1[20:4]};
	a2 <= {{3{s2[20]}},s2[20:2]} + {{6{s2[20]}},s2[20:5]};
	a3 <= {{3{s3[20]}},s3[20:2]} - {{6{s3[20]}},s3[20:5]};
	a4 <= {{1{s3[20]}},s3[20:0]} + {            s4[20:0],1'b0};
`endif
end

reg signed [22:0] b1=0, b2=0;
reg bg=0;
reg [8:0] samp=0;
reg show=0;
always @(posedge clk) begin
	b1 <= a1 - a2;
	b2 <= a3 + a4 + 1;
	if (reset) begin
		bg <= 0;
		samp <= 0;
		show <= 0;
	end else begin
		bg <= ag;
		if (bg) begin
			samp <= (samp==len-1'b1) ? 0 : samp+1'b1;
			if (samp==len-1) show <= ~show;
		end
	end
end

wire signed [21:0] c1;
sat_add #(23,22) finals(clk,b1,b2,c1);
reg cg=0;
always @(posedge clk) begin
	if (reset) cg <= 0;
	else cg <= bg & show;
end

assign outd = c1[21:2];
assign outg = cg;

endmodule
