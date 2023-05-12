`timescale 1ns / 1ns

// Simple first-order CIC filter and decimator
// Note that this module is configured with unsigned input and output!
module cic_simple_us(
	input clk,
	input [dw-1:0] data_in,
	input data_in_gate,
	input roll,  // sometimes unused, see ext_roll parameter
	output [dw-1:0] data_out,
	output data_out_gate
);
parameter ext_roll=0;  // if set, use roll port instead of internal divider
parameter dw=16;
parameter ex=10;  // decimate by 2^ex, up to 2^ex when using ext_roll

reg [dw+ex-1:0] data_int=0, data_int_h=0, diff=0;
reg [ex-1:0] div=0;
reg iroll=0, roll_r=0;  // only one of these will be used
always @(posedge clk) if (data_in_gate) begin
	data_int <= data_int + data_in;  // unsigned arithmetic, zero-padding for data_in
	{iroll, div} <= div + 1;
	roll_r <= roll;  // like data_in, roll is sampled on the cycle marked by data_in_gate
end
wire uroll = ext_roll ? roll_r : iroll;

reg data_in_gate2=0, data_out_gate_r=0;
wire deriv_gate = data_in_gate2 & uroll;
always @(posedge clk) begin
	data_in_gate2 <= data_in_gate;
	data_out_gate_r <= deriv_gate;
	if (deriv_gate) begin
		diff <= data_int - data_int_h;
		data_int_h <= data_int;
	end
end

assign data_out_gate = data_out_gate_r;
assign data_out = diff[dw+ex-1:ex];

endmodule
