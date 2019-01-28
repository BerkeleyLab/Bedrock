`timescale 1ns / 1ns

// Name: Set carrier level from I and Q
//% Upconverter
//% Provide LO at cosd and sind ports
// N.B.: full-scale negative is an invalid LO value.
module flevel_set(
	input clk,
	input signed [17:0] cosd,  // LO input
	input signed [17:0] sind,  // LO input
	input signed [i_dw-1:0] i_data,
	input i_gate,
	input i_trig,  // I baseband
	input signed [q_dw-1:0] q_data,
	input q_gate,
	input q_trig,  // Q baseband
	output signed [o_dw-1:0] o_data,
	output o_gate, o_trig, // carrier
	output time_err
);

parameter i_dw=17; // XXX don't change this
parameter q_dw=17; // XXX don't change this
parameter o_dw=16; // XXX don't change this

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
reg signed [34:0] cosp=0, sinp=0;  // 17-bit i_data * 18-bit cosd
wire signed [16:0] cosp_msb = cosp[33:17];
wire signed [16:0] sinp_msb = sinp[33:17];
reg signed [17:0] sum = 0;
reg signed [16:0] sum2 = 0;
always @(posedge clk) begin
	cosp <= i_data * cosd;
	sinp <= q_data * sind;
	sum <= cosp_msb + sinp_msb + 1;
	sum2 <= `SAT(sum,17,16);
end

reg time_err_r=0;
always @(posedge clk) begin
	time_err_r <= ~i_gate | ~q_gate;
end

assign o_data = sum2[16:1];
assign o_gate = 1'b1;
assign o_trig = 1'b0;
assign time_err = time_err_r;

endmodule
