`timescale 1ns / 1ns

// DMTD measurement of clock phasing
module phase_diff #(
	// Default parameters tuned for LCLS-II LLRF Digitizer,
	// where unknown clocks are 94.286 MHz and sampling clock is 200 MHz.
	parameter order1=1,
	parameter order2=1,
	parameter dw=14,
	parameter adv=3861,
	parameter delta=33,
	parameter ext_div1_en=0,
	parameter ext_div2_en=0
) (
	input uclk1,  // unknown clock 1
	input ext_div1, // external divider on uclk1
	input uclk2,  // unknown clock 2
	input ext_div2, // external divider on uclk2
	input sclk,   // sampling clock
	input rclk,   // readout clock (data transfer, local bus)
	// the following are in rclk domain
	output dval,
	output [dw-2:0] phdiff_out,
	output [dw-1:0] vfreq_out,
	output locked
);

// XXX vfreq_out could have extra msbs added by unwrapping, or better still,
// adding higher-order bits to phaset.

// Two phase trackers
wire [dw-1:0] phaset_out1, phaset_out2;
wire fault1, fault2;
phaset #(
	.ext_div_en(ext_div1_en),
	.order(order1), .dw(dw), .adv(adv), .delta(delta)
) track1(
	.uclk(uclk1),
	.sclk(sclk),
	.ext_div(ext_div1),
	.phase(phaset_out1),
	.fault(fault1));

phaset #(
	.ext_div_en(ext_div2_en),
	.order(order2), .dw(dw), .adv(adv), .delta(delta)
) track2 (
	.uclk(uclk2),
	.sclk(sclk),
	.ext_div(ext_div2),
	.phase(phaset_out2),
	.fault(fault2));

// Don't assume sclk phase is stable, just report the difference.
// msb of phaset_out* is useless, just represents internal divider state;
// that msb will be dropped in the pass through data_xdomain below.
reg [dw-1:0] ph_diff_sclk=0;
reg [dw-1:0] ph_sum=0, ph_sum_old=0, vernier_freq=0;
reg [10:0] cnt=0;
wire tick = &cnt;
wire fault = fault1 | fault2;
reg err_r=1;
always @(posedge sclk) begin
	ph_diff_sclk <= phaset_out1 - phaset_out2;
	ph_sum <= phaset_out1 + phaset_out2;
	cnt <= cnt+1;
	if (tick | fault) err_r <= fault;
	if (tick & locked) begin
		ph_sum_old <= ph_sum;
		vernier_freq <= ph_sum - ph_sum_old;
	end
end
assign locked = ~err_r;  // no fancy clock domain crossing

// Periodically pass the result to rclk domain
wire din_stb = &cnt[4:0] && locked;
data_xdomain #(.size(dw+dw-1)) xdom(
	.clk_in(sclk), .gate_in(din_stb), .data_in({ph_diff_sclk[dw-2:0], vernier_freq}),
	.clk_out(rclk),.gate_out(dval), .data_out({phdiff_out, vfreq_out}));

endmodule
