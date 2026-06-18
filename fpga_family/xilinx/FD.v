module FD (
	output Q,
	input C,
	input D
);

parameter INIT = 0;
reg r = INIT;
always @(posedge C) r <= D;
assign Q=r;

endmodule
