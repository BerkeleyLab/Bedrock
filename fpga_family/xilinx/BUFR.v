`timescale 1ns / 1ns
// pathetic model of Xilinx BUFR primitive
// thrown together for linting purposes; could be made much better

module BUFR #(
	parameter SIM_DEVICE="7SERIES",
	parameter BUFR_DIVIDE=1
) (
	output O,
	input I,
	input CE,
	input CLR
);
	buf b(O, I);
endmodule
