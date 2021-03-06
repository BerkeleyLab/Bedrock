`timescale 1ns / 1ns

// A synthesizable Verilog program for TT800
// Adapted from Twisted GFSR Generators II
// Makoto Matsumoto and Yoshiharu Kurita
// December 2, 1992
// http://www.math.sci.hiroshima-u.ac.jp/~m-mat/eindex.html

module tt800(
	input clk,  // timespec 3.0 ns
	input en,
	input init,
	input [31:0] initv,
	output [31:0] y
);

wire [31:0] tap1, tap2;
wire [31:0] x = tap1 ^ (tap2>>1) ^ ({32{tap2[0]}}&32'h8ebfd028);
wire [31:0] newv = init ? initv : x;
reg_delay #(.dw(32), .len(18)) d1(.clk(clk), .reset(1'b0), .gate(en), .din(newv), .dout(tap1));
reg_delay #(.dw(32), .len(7)) d2(.clk(clk), .reset(1'b0), .gate(en), .din(tap1), .dout(tap2));

wire [31:0] y1 = tap2 ^ ((tap2 << 7) & 32'h2b5b2500); /* s and b */
wire [31:0] y2 = y1  ^ ((y1 << 15) & 32'hdb8b0000); /* t and c */
wire [31:0] y3 = y2 ^ (y2 >> 16);  /* update from 1996 by Makoto Matsumoto */
reg [31:0] y_r=0;
always @(posedge clk) if (en) y_r <= y3;  // use tap2 for T800
assign y = y_r;
endmodule
