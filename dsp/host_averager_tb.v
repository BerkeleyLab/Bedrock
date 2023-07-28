`timescale 1ns / 1ns

module host_averager_tb;

// Usual boilerplate
reg clk;
integer cc;
reg fail=0;
integer tx_cnt=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("host_averager.vcd");
		$dumpvars(5,host_averager_tb);
	end
	for (cc=0; cc<4200; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	if (tx_cnt < 10) fail=1;
	if (fail) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish(0);
	end
end

// Construct stimulus
reg [23:0] data_in=88888;
reg data_s=0, read_s=0;
always @(posedge clk) begin
	data_s <= (cc%5) == 2;  // Far more frequent than real life
	if (cc < 1000) read_s <= (cc%188) == 9;
	if (cc > 2500) read_s <= (cc%311) == 16;
end

// DUT
wire [31:0] data_out;
host_averager dut (.clk(clk),
	.data_in(data_in), .data_s(data_s),
	.read_s(read_s), .data_out(data_out)
);

// Should be built-in
function integer abs;
	input integer x;
	abs = x > 0 ? x : -x;
endfunction

// Unpack
wire [23:0] average = data_out[31:8];
wire [7:0] npt = data_out[7:0];

reg read_r=0;
reg [7:0] npt_prev;
reg [23:0] avg_prev;
integer npt_model=0, npt_model_r=0;
integer npt_v;

always @(posedge clk) begin
	read_r <= read_s;
	npt_prev <= npt;
	avg_prev <= average;

	// Bare-bones model that computes expected npt. Average output currently not modeled
	npt_v = npt_model;
	if (read_s) npt_v = 0;
	if (data_s) npt_v = (npt_v<255) ? npt_v + 1 : 255;
	npt_model   <= npt_v;
	npt_model_r <= npt_model;
end

real ravg;
reg fault;
always @(negedge clk) if (read_r) begin
	if (npt != npt_model_r) begin
		fail=1;
		$display("ERROR: Unexpected NPT: %d, expected: %d", npt, npt_model);
	end
	if ((npt != npt_prev) && (average == avg_prev)) begin
		fail=1;
		$display("ERROR: Average read-out not reflecting updated NPT");
	end
	ravg = average*256.0/npt;
	if (npt == 255)
		$display("%d %d        SKIP", npt, average);
	else begin
		fault = abs(npt*data_in - average*256) > 255;
		$display("%d %d %.1f %s", npt, average, ravg, fault ? "BAD" : ".");
		if (fault) fail=1;
	end
	tx_cnt = tx_cnt + 1;
end

endmodule
