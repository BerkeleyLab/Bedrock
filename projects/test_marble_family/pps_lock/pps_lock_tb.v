`timescale 1ns / 1ns

module pps_lock_tb;

reg clk;
integer cc;
integer seed=123;

reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("pps_lock.vcd");
		$dumpvars(5,pps_lock_tb);
	end
	for (cc=0; cc<55000; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	$display("WARNING: Not a self-checking testbench. Will always pass.");
	$display("PASS");
	$finish(0);
end

// Create a fake pps with some random jitter
integer local_count=0;
reg [1:0] pps_in=0;
integer pps_start=100;
always @(posedge clk) begin
	local_count <= local_count + 1;
	if (local_count == 12499) begin
		local_count <= 0;
		pps_start <= 95 + $urandom(seed)%10;
	end
	pps_in <= 0;
	if (local_count == pps_start) pps_in <= 3;
	if (local_count == pps_start+1) pps_in <= 3;
	if (local_count == pps_start+2) pps_in <= 3;
	if ((local_count >= pps_start+2) && (local_count < pps_start+100)) pps_in <= 3;
	if (local_count == pps_start+103) pps_in <= 3;
end

// Just do one run
reg run_request=0;
always @(posedge clk) run_request <= cc>5000;

reg [15:0] dac_preset_val = 45000;
wire [15:0] dac_data;
wire dac_send, pps_out;
wire err_sign=0;
wire [13:0] dsp_status;
wire fir_enable = 0;
pps_lock #(.count_period(12500)) dut(.clk(clk),
	.pps_in(pps_in), .err_sign(err_sign),
	.fir_enable(fir_enable),
	.run_request(run_request), .dac_preset_val(dac_preset_val),
	.dac_data(dac_data), .dac_send(dac_send),
	.dsp_status(dsp_status), .pps_out(pps_out)
);
wire dsp_on = dsp_status[13];

// for easy viewing
reg [15:0] dac_sent=0;
always @(posedge clk) if (dac_send) dac_sent <= dac_data;

endmodule
