`timescale 1ns / 1ns

// DMTD measurement of clock phasing
module phase_diff #(
	// Default parameters tuned for LCLS-II LLRF Digitizer,
	// where unknown clocks are 94.286 MHz and sampling clock is 200 MHz.
	parameter dw=14,
	parameter adv=3861,
	parameter delta=33

) (
	input uclk1,  // unknown clock 1
	input uclk2,  // unknown clock 2
	input sclk,   // sampling clock
	input rclk,   // readout clock (data transfer, local bus)
	// the following are in rclk domain
	output [dw-2:0] phdiff_out,
	output [dw-1:0] vfreq_out,
	output err
);

// XXX vfreq_out could have extra msbs added by unwrapping, or better still,
// adding higher-order bits to phaset.

// Two phase trackers
wire [dw-1:0] phaset_out1, phaset_out2;
wire fault1, fault2;
phaset #(.dw(dw), .adv(adv), .delta(delta)) track1(.uclk(uclk1), .sclk(sclk),
	.phase(phaset_out1), .fault(fault1));
phaset #(.dw(dw), .adv(adv), .delta(delta)) track2(.uclk(uclk2), .sclk(sclk),
	.phase(phaset_out2), .fault(fault2));

// Don't assume sclk phase is stable, just report the difference.
// msb of phaset_out* is useless, just represents internal divider state;
// that msb will be dropped in the pass through data_xdomain below.
reg [dw-1:0] ph_diff_sclk=0;
reg [dw-1:0] ph_sum=0, ph_sum_old=0, vernier_freq=0;
reg [9:0] cnt=0;
wire tick = &cnt;
wire fault = fault1 | fault2;
reg err_r=0;
always @(posedge sclk) begin
	ph_diff_sclk <= phaset_out1 - phaset_out2;
	ph_sum <= phaset_out1 + phaset_out2;
	cnt <= cnt+1;
	if (tick | fault) err_r <= fault;
	if (tick) begin
		ph_sum_old <= ph_sum;
		vernier_freq <= ph_sum - ph_sum_old;
	end
end
assign err = err_r;  // no fancy clock domain crossing

// Periodically pass the result to rclk domain
data_xdomain #(.size(dw-1)) xdom1(
	.clk_in(sclk), .gate_in(&cnt[4:0]), .data_in(ph_diff_sclk[dw-2:0]),
	.clk_out(rclk), .data_out(phdiff_out));
data_xdomain #(.size(dw)) xdom2(  // inefficient
	.clk_in(sclk), .gate_in(&cnt[4:0]), .data_in(vernier_freq),
	.clk_out(rclk), .data_out(vfreq_out));

endmodule
