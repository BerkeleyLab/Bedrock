`timescale 1ns / 1ns

module beam_tb;

reg clk;
reg reset;
integer cc;
reg trace;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("beam.vcd");
		$dumpvars(5,beam_tb);
	end
	trace = $test$plusargs("trace");
	reset=0;
	for (cc=0; cc<1500; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

// Beam pulse rate = 1300 MHz / 1400 = 928.57 kHz
// Clock rate = 1320 MHz / 14 = 94.286 MHz
// 13 beam pulses = 1320 clocks = 14 us
reg [11:0] phase_step = 12'd13;
reg [11:0] modulo = -12'd1320;
wire [11:0] pulse;
beam dut(.clk(clk), .ena(1'b1), .reset(reset),
	.pulse(pulse),
	.phase_step(phase_step), .modulo(modulo));

always @(posedge clk) begin
	#1;
	if (trace && (pulse!=0)) $display(cc,pulse);
end

// Keep from having to look at 3000 boring cycles at the beginning
// of a simulation
initial begin #1; dut.phase=-26; end

endmodule
