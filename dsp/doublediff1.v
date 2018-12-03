`timescale 1ns / 1ns

module doublediff1(clk, d_in, g_in, d_out, g_out, reset);
parameter dw=28;
parameter gw=1;
parameter dsr_len=4;
	input clk;
	input reset;
	input [dw-1:0] d_in;
	input [gw-1:0] g_in;
	output [dw-1:0] d_out;
	output [gw-1:0] g_out;

reg signed [dw-1:0] d1=0, d2=0;
wire [gw-1:0] valid1, valid2;
wire [dw-1:0] dpass1, dpass2;

reg_delay #(.dw(dw), .len(dsr_len))
	s1(.clk(clk), .gate(g_in[0]), .din(d_in), .dout(dpass1), .reset(reset));

reg_delay #(.dw(dw), .len(dsr_len))
	s2(.clk(clk), .gate(valid1[0]), .din(d1), .dout(dpass2), .reset(reset));

reg_delay #(.dw(gw), .len(1))
	reg_delay_g1(.clk(clk), .gate(1'b1), .din(g_in), .dout(valid1), .reset(reset));

reg_delay #(.dw(gw), .len(1))
	reg_delay_g2(.clk(clk), .gate(1'b1), .din(valid1), .dout(valid2), .reset(reset));

always @(posedge clk) begin
	d1 <= reset ? {dw{1'b0}} : (g_in[0] ? d_in - dpass1 : d1);
	d2 <= reset ? {dw{1'b0}} : (valid1[0] ?  d1 - dpass2 : d2);
end
assign d_out = d2;
assign g_out = valid2;
endmodule
