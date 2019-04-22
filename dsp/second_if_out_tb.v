`timescale 1ns / 1ns

module second_if_out_tb;

reg clk, trace;
integer cc;
integer out_file;
//reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("sel4v/second_if_out.vcd");
		$dumpvars(5,second_if_out_tb);
	end
	if ($test$plusargs("trace")) begin
		trace = 1;
		out_file = $fopen("second_if_out.dat", "w");
	end
	for (cc=0; cc<360; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	//$display("%s", fail ? "FAIL" : "PASS");
	$display("WARNING: Not a self-checking testbench. Will always pass.");
	$display("%s","PASS");
end

reg [1:0] div_state=0;
wire iq = div_state[0];
reg signed [17:0] drive=0;
always @(posedge clk) begin
	div_state <= div_state+1;
	drive <= iq ? 0 : cc>90 ? 120000 : 20000;
end

// DDS 7/33
wire [19:0] phase_step_h = 222425;
wire [11:0] phase_step_l = 868;
wire [11:0] modulo = 4;
wire signed [17:0] cosa, sina;
// was 74840, but divide by abs(1+i/16)
rot_dds #(.lo_amp(18'd74694)) dds(.clk(clk), .reset(1'b0),
	.cosa(cosa), .sina(sina),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo)
);

wire signed [17:0] out_xy;
wire signed [15:0] dac1_out0, dac1_out1, dac2_out0, dac2_out1;
second_if_out dut(.clk(clk), .div_state(div_state), .drive(drive), .enable(1'b1),
	.cosa(cosa), .sina(sina),
	.dac1_out0(dac1_out0), .dac1_out1(dac1_out1),
	.dac2_out0(dac2_out0), .dac2_out1(dac2_out1)
);

always @(negedge clk) if (trace) begin
	$fwrite(out_file, "%d\n", dac1_out0);
	$fwrite(out_file, "%d\n", dac1_out1);
end

endmodule
