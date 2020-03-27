`timescale 1ns / 1ns

module ssb_out_tb;

parameter DUT_IQ_OUT=1;

reg clk, trace;
integer cc;
integer out_file;
// reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("ssb_out.vcd");
		$dumpvars(5,ssb_out_tb);
	end
	if ($test$plusargs("trace")) begin
		trace = 1;
		out_file = $fopen("ssb_out.dat", "w");
	end
	$display("DUT_IQ_OUT=%d", DUT_IQ_OUT);
	for (cc=0; cc<360; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("WARNING: Not a self-checking testbench. Will always pass.");
	$display("%s","PASS");
	$finish();
end

reg [1:0] div_state=0;
wire iq = div_state[0];
reg signed [17:0] drive=0;
always @(posedge clk) begin
	div_state <= div_state + 1;
	drive <= iq ? 0 : cc>40 ? 120000 : 20000;
end

// DDS
wire [19:0] phase_step_h = 166111;
wire [11:0] phase_step_l = 200;
wire [11:0] modulo = 56;
wire signed [17:0] cosa, sina;
rot_dds #(.lo_amp(18'd74840)) dds(.clk(clk), .reset(1'b0),
	.cosa(cosa), .sina(sina),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo)
);

wire signed [17:0] out_xy;
wire signed [15:0] dac1_out0, dac1_out1, dac2_out0, dac2_out1;
ssb_out #(.IQ_OUT(DUT_IQ_OUT)) dut(
	.clk(clk), .div_state(div_state), .drive(drive), .enable(1'b1),
	.cosa(cosa), .sina(sina),
	.dac1_out0(dac1_out0), .dac1_out1(dac1_out1),
	.dac2_out0(dac2_out0), .dac2_out1(dac2_out1)
);

always @(negedge clk) if (trace) begin
	if (DUT_IQ_OUT) begin
		$fwrite(out_file, "%d %d\n", dac1_out0, dac2_out0);
		$fwrite(out_file, "%d %d\n", dac1_out1, dac2_out1);
	end else begin
		$fwrite(out_file, "%d\n", dac1_out0);
		$fwrite(out_file, "%d\n", dac1_out1);
	end
end

endmodule
