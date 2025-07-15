// Pathetic model of Xilinx ODDR2 cell (Spartan-6) for simulation
// Ignores set and reset inputs
module ODDR2 (
	output Q,
	input C0,
	input C1,
	input CE,
	input D0,
	input D1,
	input R,
	input S
);

parameter DDR_ALIGNMENT = "NONE";
parameter INIT = 1'b0;
parameter SRTYPE = "SYNC";

reg Q0=INIT, Q1=INIT;
always @(posedge C0) if (CE) Q0 <= D0;
always @(posedge C1) if (CE) Q1 <= D1;
always @(negedge C0) Q0 <= Q1;

buf b(Q, Q0);

endmodule
