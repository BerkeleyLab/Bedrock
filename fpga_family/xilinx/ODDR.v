// pathetic model of Xilinx DDR output cell
// ignores set and reset inputs
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

// verilator lint_save
// verilator lint_off MULTIDRIVEN
reg qx=INIT, hold=INIT;
always @(negedge C) qx <= hold;
always @(posedge C) if (CE) qx <= D1;
// verilator lint_restore
always @(posedge C) if (CE) hold <= D2;
assign Q = qx;

endmodule
