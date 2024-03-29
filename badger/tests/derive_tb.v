// Cross-checks that the explicit machine-generated CRC code
// found in crc_genguts.vh and therefore crc8e_guts.v is actually correct
`timescale 1ns / 1ns

module derive_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("derive.vcd");
		$dumpvars(5,derive_tb);
	end
	for (cc=0; cc<100; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	if (fail) begin
		$display("FAIL");
		$stop(0);
	end else begin
		$display("PASS");
		$finish(0);
	end
end

parameter dw=32;
parameter ord=16;
parameter poly=16'h1021;

// Input vector generation
reg [dw-1:0] din=0;
reg zero=0;
always @(posedge clk) begin
	zero <= cc < 3;
	din <= $random;
end

// Instantiate both implementations
wire [ord-1:0] crc_inf_o, crc_exp_o;
crc_inferred #(.dw(dw), .poly(poly), .ord(ord)) ci(
	.clk(clk), .din(din), .zero(zero), .crc(crc_inf_o));
crc_explicit #(.dw(dw), .ord(ord)) ce(
	.clk(clk), .din(din), .zero(zero), .crc(crc_exp_o));

// Fail if the two disagree
wire mismatch = crc_inf_o != crc_exp_o;
always @(posedge clk) if (mismatch) fail <= 1;

endmodule

// Possibly synthesizable, if you have a good synthesizer
module crc_inferred #(
	parameter ord=16,
	parameter poly=16'h1021,
	parameter dw=16
) (
	input clk,
	input [dw-1:0] din,
	input zero,
	output reg [ord-1:0] crc
);
wire [ord-1:0] O = zero ? {ord{1'b0}} : crc;
integer i;
reg [ord-1:0] crc_nx;
reg b;
always @(posedge clk) begin
	crc_nx = O;
	for (i = 0; i<dw; i=i+1) begin
		b = din[dw-1-i] ^ crc_nx[ord-1];
		crc_nx = (crc_nx<<1) ^ (poly & {ord{b}});
	end
	crc <= crc_nx;
end
initial crc=0;
endmodule

// Explicit logic equations, generated by crc_derive.c
module crc_explicit #(
	parameter ord=16,
	parameter dw=16
) (
	input clk,
	input [dw-1:0] din,
	input zero,
	output reg [ord-1:0] crc
);
wire [ord-1:0] O = zero ? {ord{1'b0}} : crc;
wire [dw-1:0] D = din;
always @(posedge clk) begin
// crc_derive command line arguments must match dw and ord
`include "crc_genguts.vh"
end
initial crc=0;
endmodule
