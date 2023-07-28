`timescale 1ns / 1ns

module cic_simple_us_tb;

// Usual boilerplate
reg clk;
integer cc;
reg fail=0;
integer outs=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("cic_simple_us.vcd");
		$dumpvars(5,cic_simple_us_tb);
	end
	for (cc=0; cc<900; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	$display("%d outputs recorded, want 5", outs);
	if (outs != 5) fail=1;
	if (fail) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish(0);
	end
end

// Construct stimulus
reg [15:0] data_in=44444;
reg data_in_gate=0;
always @(posedge clk) begin
	data_in_gate <= (cc%5) == 2;  // Far more frequent than real life
	if (cc==400) data_in=777;
end

// DUT
wire [15:0] data_out;
wire data_out_gate;
cic_simple_us #(.dw(16), .ex(5)) dut (.clk(clk),
	.data_in(data_in), .data_in_gate(data_in_gate), .roll(1'b0),
	.data_out(data_out), .data_out_gate(data_out_gate)
);

reg fault;
always @(negedge clk) if (data_out_gate) begin
	outs = outs + 1;
	fault = 0;
	if (outs == 2 && data_out != 44444) fault=1;
	if (outs == 4 && data_out !=   777) fault=1;
	$display("%d %d %s", outs, data_out, fault ? "BAD" : ".");
	if (fault) fail=1;
end

endmodule
