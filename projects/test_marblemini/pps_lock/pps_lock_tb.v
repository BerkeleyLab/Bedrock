`timescale 1ns / 1ns

module pps_lock_tb;

reg clk;
integer cc;
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
	$display("%s", fail ? "FAIL" : "PASS");
end

// Create a fake pps, actually aligns perfectly for now
integer local_count=0;
reg pps_in=0;
always @(posedge clk) begin
	local_count <= (local_count==12499) ? 0 : local_count+1;
	pps_in <= local_count == 100;
end

// Just do one run
reg run_request=0;
always @(posedge clk) run_request <= cc>5000;

reg signed [15:0] dac_preset_val = 20000;
wire [15:0] dac_data;
wire dac_send, pps_out;
wire err_sign=0;
wire [31:0] dsp_status;
pps_lock #(.count_period(12500)) dut(.clk(clk),
	.pps_in(pps_in), .err_sign(err_sign),
	.run_request(run_request), .dac_preset_val(dac_preset_val),
	.dac_data(dac_data), .dac_send(dac_send),
	.dsp_status(dsp_status), .pps_out(pps_out)
);
wire dsp_on = dsp_status[13];

endmodule
