`timescale 1ns / 1ns

module addsubg #(
	parameter size=16
) (
	input [size-1:0] a,
	input [size-1:0] b,
	output [size-1:0] sum,
	input control
);
	assign sum = control ? (a + b) : (a - b);
endmodule
