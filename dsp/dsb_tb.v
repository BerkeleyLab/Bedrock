`timescale 1ns / 1ns
`include "constants.vams"

module dsb_tb;

reg clk, trace, reset;
integer cc;
integer out_file;


initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("dsb.vcd");
		$dumpvars(5,dsb_tb);
	end

	if($test$plusargs("trace")) begin
	trace = 1;
		out_file = $fopen("duc.dat", "w");
	end

	reset = 0;
	for (cc=0; cc<44; cc=cc+1) begin
		clk=0; #8.7206; //als-u dsp clock
		clk=1; #8.7206;
	end
	$finish();
end

reg div_state=0;
wire iq = div_state;
reg signed [17:0] drive=0;

always @(posedge clk) begin
	div_state <= div_state + 1;
	drive <= iq ? 0 : cc>40 ? 120000 : 20000;
end


// DDS
parameter [17:0] LO_AMP = 18'd74840;
parameter CORDIC_GAIN = 1.64676;
reg [19:0] phase_step_h = 381300;
reg [11:0] phase_step_l = 1488;
reg [11:0] modulo = 4;
wire signed [17:0] sina, cosa;

rot_dds  #(.lo_amp(LO_AMP)) dds(.clk(clk), .reset(reset),
	.sina(sina), .cosa(cosa),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l), .modulo(modulo)
);

wire signed [15:0] dac_out;

dsb dut(
	.clk(clk), .div_state(div_state), .drive(drive),
	.cosa(cosa), .sina(sina),
	.dac_out(dac_out)
);

always @(negedge clk) begin
	if (trace) begin
		$fwrite(out_file, "%d \n", dac_out);
	end
end

real amp;
initial amp = LO_AMP * CORDIC_GAIN;// (74840 * 1.64676) = 123243.5
real tha, cosr, sinr;
real variance=0;
integer npt;
reg fault;
always @(negedge clk) if (cc>30) begin
	tha = (cc)*`M_TWO_PI*4.0/11.0;
	sinr = amp*$sin(tha);
	cosr = amp*$cos(tha);
	$display("%d %d %d %9.1f   %d %9.1f", cc, tha, sina, sinr, cosa, cosr);
	variance = variance + (sina-sinr)**2 + (cosa-cosr)**2;
	if (cc==43) begin
		$display("DDS: rms error = %.3f bits", $sqrt(variance/26.0));
		fault = (variance/26 > 0.7);
		$display("DDS: %s", fault ? "FAIL" : "PASS");
	end
end

endmodule
