`timescale 1ns / 1ns

module second_if_out_tb;

reg clk, trace=0;
integer cc;
integer out_file;
reg lo_mode;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("second_if_out.vcd");
		$dumpvars(5,second_if_out_tb);
	end

	if (!$value$plusargs("if_lo=%d", lo_mode)) lo_mode=1'b0;
	$display("Testing %s MHz IF out mode.", lo_mode==0 ? "145" : "60");

	if ($test$plusargs("trace")) begin
		trace = 1;
		out_file = $fopen("second_if_out.dat", "w");
	end
	for (cc=0; cc<360; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	if (trace) $display("Please use contents of second_if_out.dat for functional validation");
	else $display("WARNING: Not a self-checking testbench. Will always pass.");
	$display("PASS");
	$finish();
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
wire signed [17:0] cosa_145, sina_145;
wire signed [17:0] cosa_60, sina_60;

// Raw LO = 74840
// For 145 MHz IF output, divide LO by abs(1+i/16) to account for internal multiplication
localparam [17:0] lo_amp_145 = 74694;
localparam [17:0] lo_amp_60 = 74840;

rot_dds #(.lo_amp(lo_amp_145)) dds_145 (.clk(clk), .reset(1'b0),
	.cosa(cosa_145), .sina(sina_145),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo)
);
rot_dds #(.lo_amp(lo_amp_60)) dds_60 (.clk(clk), .reset(1'b0),
	.cosa(cosa_60), .sina(sina_60),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo)
);

assign cosa = lo_mode==0 ? cosa_145: cosa_60;
assign sina = lo_mode==0 ? sina_145: sina_60;

wire signed [17:0] out_xy;
wire signed [15:0] dac1_out0, dac1_out1, dac2_out0, dac2_out1;
second_if_out dut(.clk(clk), .div_state(div_state), .drive(drive), .enable(1'b1),
	.lo_sel(lo_mode),
	.cosa(cosa), .sina(sina),
	.dac1_out0(dac1_out0), .dac1_out1(dac1_out1),
	.dac2_out0(dac2_out0), .dac2_out1(dac2_out1)
);

always @(negedge clk) if (trace) begin
	$fwrite(out_file, "%d\n", dac1_out0);
	$fwrite(out_file, "%d\n", dac1_out1);
end

endmodule
