`timescale 1ns / 1ns
module timestamp_tb;

reg clk, evt;

integer cc;
integer errors=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("timestamp.vcd");
		$dumpvars(5,timestamp_tb);
	end
	clk=0;
	evt=0;
	for (cc=0; cc<5000; cc=cc+1) begin
		#10; clk=1;
		#11; clk=0;
	end
	if (errors==0) begin
		$display("PASS");
		$finish(0);
	end else begin
		$display("FAIL");
		$stop(0);
	end
end

reg slow_op=0, slow_snap=0, aux_trig=0;
wire [7:0] shift_out;
wire aux_skip;
timestamp #(.dw(4), .aux_reg(1)) mut(.clk(clk), .slow_op(slow_op), .slow_snap(slow_snap),
	.shift_in(8'h2a), .shift_out(shift_out),
	.aux_trig(aux_trig), .aux_skip(aux_skip));

integer right_answer;
reg [31:0] sr=0;
wire [9:0] phase=cc%611;
wire grab=phase==308;
reg fault;
always @(posedge clk) begin
	slow_op <= (phase%35) == 20;
	slow_snap <= phase == 20;
	aux_trig <= (cc == 500) | (cc == 2700);
	if (slow_snap) right_answer <= cc;
	if (slow_op & ~slow_snap) sr <= {shift_out[3:0],sr[31:4]};
	if (grab) begin
		fault = right_answer!=((sr>>1)-9);
		$display("%x  %x  %s", right_answer, (sr>>1)-9, fault?"FAULT":"    .");
		if (fault) errors = errors+1;
	end
end
wire [23:0] upper_bits=right_answer[26:3];

endmodule
