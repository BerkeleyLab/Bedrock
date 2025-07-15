`timescale 1ns / 1ns

module cstageg #(
	parameter shift=1,
	parameter zwidth=16,
	parameter width=16,
	parameter def_op=0
) (
	input clk,
	input [1:0] opin,
	input [width-1:0] xin,
	input [width-1:0] yin,
	input [zwidth-1:0] zin,
	input [zwidth-1:0] ain,
	output reg [1:0] opout,
	output reg [width-1:0] xout,
	output reg [width-1:0] yout,
	output reg [zwidth-1:0] zout
);

	initial begin
		opout=def_op;  xout=0;  yout=0;  zout=0;
	end

	reg control_h=0;  // local saved state to implement follow mode
	wire control_l = opin[0] ? ~yin[width-1] : zin[zwidth-1];
	wire control = opin[1] ? ~control_h : control_l;
	wire [width-1:0] xv, yv;
	wire [zwidth-1:0] zv;
	addsubg #( width) ax(xin, {{(shift){yin[width-1]}},yin[width-1:shift]}, xv,  control);
	addsubg #( width) ay(yin, {{(shift){xin[width-1]}},xin[width-1:shift]}, yv, ~control);
	addsubg #(zwidth) az(zin,                                         ain , zv,  control);
	always @(posedge clk) begin
		opout <= opin;
		xout  <= xv;
		yout  <= yv;
		zout  <= zv;
		control_h <= control_l;
	end
endmodule
