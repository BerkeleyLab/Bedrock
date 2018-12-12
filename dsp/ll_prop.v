`timescale 1ns / 1ns

// Keep the interface to this module simple:
//  all IQ inputs and outputs are co-phased,
//  i.e., I values when iq is high, Q values when iq is low.
module ll_prop(
	input clk,
	input iq,
	input signed [17:0] in_iq,
	output signed [17:0] out_iq,
	input [1:0] coarse_scale,  // max gain 8, 64, 512, 4096
	// slowly varying control inputs, also IQ multiplexed
	input signed [17:0] set_iq,
	input signed [17:0] gain_iq,
	input signed [17:0] drive_iq
);

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

reg signed [18:0] err_iq=0;
reg signed [22:0] err_iq_s=0;
reg signed [17:0] err_iq_lim=0;
always @(posedge clk) begin
	err_iq <= in_iq - set_iq;
	err_iq_s <= coarse_scale[0] ? (err_iq <<< 4) : (err_iq <<< 1);
	err_iq_lim <= `SAT(err_iq_s,22,17);
end

wire signed [17:0] prod_iq;
vectormul mul(.clk(clk), .gate_in(1'b1), .iq(iq),
	.x(err_iq_lim), .y(gain_iq), .z(prod_iq));

reg signed [25:0] prod_iq_s=0;
reg signed [14:0] prod_iq_lim=0;  // max contribution 1/8 of full scale
// add circular and/or configurable limit?
// add peak/rms error monitoring?
reg signed [18:0] sum_iq=0;
reg signed [17:0] sum_iq_s=0;
always @(posedge clk) begin
	prod_iq_s <= coarse_scale[1] ? (prod_iq <<< 8) : (prod_iq <<< 2);
	prod_iq_lim <= `SAT(prod_iq_s,25,14);
	sum_iq <= prod_iq_lim + drive_iq;
	sum_iq_s <= `SAT(sum_iq,18,17);
end

assign out_iq=sum_iq_s;

endmodule
