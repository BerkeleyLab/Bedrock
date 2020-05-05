`timescale 1ns / 1ns

`define AUTOMATIC_decode
`define AUTOMATIC_outer_prod
`define LB_DECODE_outer_prod_tb
`include "outer_prod_tb_auto.vh"

module outer_prod_tb;

// Nominal clock is 188.6 MHz, corresponding to 94.3 MHz ADC clock.
// 166.7 MHz is just a convenient stand-in.
reg clk;
reg lb_clk;
reg trace;
integer cc;
`ifdef SIMULATE
initial begin
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("outer_prod.vcd");
		$dumpvars(5,outer_prod_tb);
	end
	for (cc=0; cc<300; cc=cc+1) begin
		clk=0; #3;
		clk=1; #3;
	end
end
`endif

// Local bus
reg [31:0] lb_data=0;
reg [14:0] lb_addr=0;
reg lb_write=0;

`AUTOMATIC_decode

// Configure number of modes processed
parameter n_mech_modes = 7;
integer n_cycles = n_mech_modes * 2;
reg start=0;
always @(posedge clk) start <= cc%n_cycles==0;

// Fake the drive signal
reg signed [17:0] x=2000;
always @(posedge clk) begin
	x <= x+11;
end

wire signed [17:0] result;
(* lb_automatic *)
outer_prod outer_prod  // auto
	(.clk(clk), .start(start),
	.x(x), .result(result),
	`AUTOMATIC_outer_prod
);

integer ix;
initial begin
	#1;  // lose time zero races
	dp_outer_prod_k_out.mem[0]=80000;  // out of 2^17
	dp_outer_prod_k_out.mem[4]=100000;  // out of 2^17
	dp_outer_prod_k_out.mem[13]=80000;  // out of 2^17
end

always @(posedge clk) if (trace) begin
	if (cc>16 && cc%n_cycles == 4) $display("%d", result);
end

endmodule
