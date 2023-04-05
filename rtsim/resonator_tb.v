`timescale 1ns / 1ns

`define AUTOMATIC_decode
`define AUTOMATIC_resonator
`define LB_DECODE_resonator_tb
`include "resonator_tb_auto.vh"

module resonator_tb;

// Nominal clock is 188.6 MHz, corresponding to 94.3 MHz ADC clock.
// 166.7 MHz is just a convenient stand-in.
reg clk;
wire lb_clk = clk;
reg trace;
integer cc;
`ifdef SIMULATE
initial begin
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("resonator.vcd");
		$dumpvars(5,resonator_tb);
	end
	for (cc=0; cc<3000; cc=cc+1) begin
		clk=0; #3;
		clk=1; #3;
	end
	$finish();
end
`endif //  `ifdef SIMULATE

// Local bus, not really used here
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
reg signed [17:0] drive;
always @(posedge clk) begin
	drive <= 18'bx;
	if (cc%n_cycles == 12) drive <= 0;
	if (cc%n_cycles == 13) drive <= 1000;
end

wire signed [17:0] position;
wire clip;
(* lb_automatic *)
resonator resonator  // auto
	(.clk(clk), .start(start),
	.drive(drive),
	.position(position), .clip(clip),
	`AUTOMATIC_resonator
);

`ifdef SIMULATE
integer ix;
integer scale=7;
initial begin
	#1;  // lose time zero races
	resonator.ab.mem[4]=100000000;  // out of 2^35
	resonator.ab.mem[5]=0;
	dp_resonator_prop_const.mem[4]=-80000 | {scale,18'b0};  // out of 2^17
	dp_resonator_prop_const.mem[5]=120000 | {scale,18'b0};
end

reg signed [17:0] last=0;
always @(posedge clk) if (trace) begin
	last <= position;
	if (cc>16 && cc%n_cycles == 4) $display("%d %d", last, position);
end
`endif

endmodule
