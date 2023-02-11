`timescale 1ns / 1ns

module banyan_tb;
parameter dw=7;
reg clk;
reg trace, squelch;
integer cc;
integer pass_count=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("banyan_tb.vcd");
		$dumpvars(5,banyan_tb);
	end
	trace = $test$plusargs("trace");
	squelch = $test$plusargs("squelch");
	for (cc=0; cc<2052; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	// 1*1 + 70*2 + 28*4 + 8*8 = 317
	if (pass_count == 317)
		$display("PASS");
		$finish();
	end else begin
		$display("FAIL %d", pass_count);
		$stop();
end

// Create input test data that is easy to understand
reg [8*dw-1:0] test;
integer ix;
initial for (ix=0; ix<8; ix=ix+1) test[(ix)*dw+:dw] = (ix+0)*1;

// Fully exercise an 11-bit control word combining mask and time_step
// A lot of these patterns make no sense, but run through them anyway.
// Only patterns that are relevant will be checked.
reg [10:0] ctl=0;
always @(posedge clk) ctl <= ctl + 1;

wire [8*dw-1:0] result;
wire [7:0] mask_in = ctl[10:3];
wire [2:0] time_state = ctl[2:0];
wire [7:0] mask_out;
banyan #(.rl(3), .np(8), .dw(dw)) dut3(.clk(clk),
	.time_state(time_state), .mask_in(mask_in), .data_in(test[55:0]),
	.data_out(result), .mask_out(mask_out));

// Time align the input conditions with the (pipelined) output
parameter pipe_stages = 4;
reg [11*pipe_stages-1:0] ctl_pipe=0;
reg [7:0] mask_out_r=0;
always @(posedge clk) begin
	ctl_pipe <= {ctl_pipe[(pipe_stages-1)*11-1:0],ctl};
	mask_out_r <= mask_out;
end

// Display
reg [7:0] mask_disp;
reg [2:0] ts_disp;
reg [3:0] bit_cnt;
integer jx, fanout, appears, good;
reg fault;
reg [7:0] showme[0:7];
always @(negedge clk) begin
	mask_disp = ctl_pipe[pipe_stages*11-1 -: 8];
	ts_disp   = ctl_pipe[pipe_stages*11-9 -: 3];
	bit_cnt = 0;
	for (ix=0; ix<8; ix=ix+1)
		bit_cnt = bit_cnt + mask_disp[ix];
	fanout = 8/bit_cnt;
	if ((bit_cnt == 1 || bit_cnt == 2 || bit_cnt == 4 || bit_cnt == 8) && (ts_disp < fanout)) begin
		// This check process is purposefully insensitive to the order
		// that data appears in the output.  In real life this order
		// will need to be "well known" by the host software that reads
		// and assembles the results.
		good = 0;
		for (ix=0; ix<8; ix=ix+1) begin
			if (mask_disp[ix]) begin
				// channel ix is found in the mask word, so it
				// should appear exactly once in the output data
				appears = 0;
				for (jx=0; jx<bit_cnt; jx+=1)
					if (result[(ts_disp%fanout+jx*fanout)*dw+dw-1 -: dw] == (ix+0)) appears += 1;
				if (appears == 1) good += 1;
			end
		end
		fault = good != bit_cnt;
		if (fault || trace) begin
			for (ix=0; ix<8; ix=ix+1) begin
				showme[ix] = ".";
				if (mask_out_r[ix] || ~squelch) showme[ix] = result[dw*(ix+1)-1 -: dw] + "0";
			end
			$display("%x %d %x %1d : %c %c %c %c %c %c %c %c %s",
				mask_disp, ts_disp, mask_out_r, bit_cnt,
				showme[7], showme[6], showme[5], showme[4], showme[3], showme[2], showme[1], showme[0],
				fault ? "FAULT" : "     .");
		end
		if (fault == 0) pass_count = pass_count + 1;
	end
end
endmodule
