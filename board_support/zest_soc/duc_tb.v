`timescale 1ns / 1ns
module duc_tb;

reg clk=0, trace=0, dac_clk=0;
integer cc;
integer out_file;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("duc.vcd");
		$dumpvars(5,duc_tb);
	end

	if ($test$plusargs("trace")) begin
		trace = 1;
		out_file = $fopen("duc.dat", "w");
	end
	// Don't take the time scaling in this simulation seriously.
	// We just have to make sure of the 2:1 ratio between clk and dac_clk.
	// In real life, the clk period is 10.606 ns.
	for (cc=0; cc<460; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	if (trace) $display("Please use contents of duc.dat for functional validation");
	else $display("WARNING: Not a self-checking testbench. Will always pass.");
	$display("PASS");
	$finish(0);
end

always #2 dac_clk = ~dac_clk;

reg [1:0] div_state=0;
wire iq = div_state[0];
reg signed [16:0] drive_i=0, drive_q=0;
always @(posedge clk) begin
	div_state <= div_state+1;
	drive_i <= cc>90 ? 120000 : 0;
	drive_q <= cc>90 ? 20000  : 0;
end

// DDS 7/33
wire [19:0] phase_step_h = 222425;
wire [11:0] phase_step_l = 868;
wire [11:0] modulo = 4;
wire signed [17:0] cosa, sina;

// Raw LO = 74840
// For 145 MHz IF output, divide LO by abs(1+i/16) to account for internal multiplication
localparam [17:0] lo_amp_145 = 74694;

rot_dds #(.lo_amp(lo_amp_145)) dds_145 (.clk(clk), .reset(1'b0),
	.cosa(cosa), .sina(sina),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo)
);

localparam DW = 17;
wire signed [DW-1:0] interp_coeff = 0;
wire signed [DW-2:0] dac_out;
wire signed [DW-2:0] dac_mon;
duc dut(.adc_clk(clk), .dac_clk(dac_clk),
	.div_state(div_state), .dac_iq_phase(1'b0),
	.drive_i(drive_i), .drive_q(drive_q),
	.cosa(cosa), .sina(sina),
        .interp_coeff(interp_coeff), .dac_mon(dac_mon),
	.dac_out(dac_out)
);

always @(negedge dac_clk) if (trace) begin
	$fwrite(out_file, "%d\n", dac_out);
end

endmodule
