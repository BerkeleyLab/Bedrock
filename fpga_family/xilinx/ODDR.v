// pathetic model of Xilinx DDR output cell
// ignores set and reset inputs, and the SRTYPE and DDR_CLK_EDGE parameters
module ODDR (
	input S,
	input R,
	input D1,
	input D2,
	input CE,
	input C,
	output Q
);

parameter DDR_CLK_EDGE = "SAME_EDGE";
parameter INIT = 0;
parameter SRTYPE = "SYNC";

reg hold1=INIT, hold2=INIT;
always @(posedge C) if (CE) begin
	hold1 <= D1;
	hold2 <= D2;
end
assign Q = C ? hold1 : hold2;

endmodule
