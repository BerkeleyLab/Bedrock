`timescale 1ns / 1ns
`include "constants.vams"

module rot_dds_tb;

reg clk;
reg reset;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("rot_dds.vcd");
		$dumpvars(5,rot_dds_tb);
	end
	reset=0;
	for (cc=0; cc<44; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

// Values for Argonne RIA test documented in rot_dds.v
parameter [17:0] lo_amp = 18'd79590;
parameter cordic_gain = 1.64676;
reg [19:0] phase_step_h=725937;
reg [11:0] phase_step_l=945;
reg [11:0] modulo=1;

wire signed [17:0] sina, cosa;
rot_dds dut(.clk(clk), .reset(reset),
	.sina(sina), .cosa(cosa),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l), .modulo(modulo)
);

real amp;
initial amp = lo_amp * cordic_gain;  // (79590 * 1.64676) = 131065.7
real tha, cosr, sinr;
real variance=0;
integer npt;
reg fault;
always @(negedge clk) if (cc>30) begin
	tha = (cc+4)*`M_TWO_PI*9.0/13.0;  // Freq_IF/Freq_sampling
	sinr = amp*$sin(tha);
	cosr = amp*$cos(tha);
	// $display("%d %d %9.1f   %d %9.1f", cc, sina, sinr, cosa, cosr);
	variance = variance + (sina-sinr)**2 + (cosa-cosr)**2;
	if (cc==43) begin
		$display("rms error = %.3f bits", $sqrt(variance/26.0));
		fault = (variance/26 > 0.7);
		if (fault) $stop("FAIL");
		else $finish("PASS");
	end
end

endmodule
