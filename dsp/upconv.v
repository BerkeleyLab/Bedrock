`timescale 1ns / 1ns

module upconv(
	input clk,
	input signed [15:0] in_d,   // baseband, interleaved I and Q
	input in_strobe,            // Set at I time, Q follows
	input signed [15:0] cos,    // LO input
	input signed [15:0] sin,    // LO input
	output signed [15:0] cos_interp,  // interpolated output immediately before upconversion
	output signed [15:0] sin_interp,
	output signed [15:0] out_d  // at IF
);

reg in_strobe1=0;
always @(posedge clk) in_strobe1 <= in_strobe;

wire signed [17:0] d2out;
wire d2strobe0;
doublediff #(.dw(18), .dsr_len(2)) d2dt2(.clk(clk),
	.d_in({{2{in_d[15]}},in_d}), .g_in(in_strobe|in_strobe1),
	.d_out(d2out), .g_out(d2strobe0)
);

reg signed [17:0] d2out_d=0, d2i=0, d2q=0;
reg d2strobe1=0, d2strobe2=0;
always @(posedge clk) begin
	d2out_d <= d2out;
	d2strobe1 <= d2strobe0;
	d2strobe2 <= d2strobe1;
	if (d2strobe1&~d2strobe2) d2i <= d2out_d;
	if (d2strobe1&~d2strobe2) d2q <= d2out;

end

wire signed [15:0] i2i, i2q;
interp1 inti(.clk(clk), .x(d2i), .y(i2i));
interp1 intq(.clk(clk), .x(d2q), .y(i2q));

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
reg signed [31:0] cosp=0, sinp=0;
wire signed [17:0] cosp_msb = cosp[30:13];
wire signed [17:0] sinp_msb = sinp[30:13];
reg signed [18:0] sum=0;
reg signed [16:0] sum2=0;
always @(posedge clk) begin
	cosp <= i2i*cos;
	sinp <= i2q*sin;
	sum <= cosp_msb + sinp_msb + 1;
	sum2 <= `SAT(sum,18,16);
end
assign out_d = sum2[16:1];

assign cos_interp = i2i;
assign sin_interp = i2q;
`undef SAT

endmodule
