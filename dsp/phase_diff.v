`timescale 1ns / 1ns

// DMTD measurement of clock phasing
module phase_diff #(
	// Default parameters tuned for LCLS-II LLRF Digitizer,
	// where unknown clocks are 94.286 MHz and sampling clock is 200 MHz.
	parameter order1=1,
	parameter order2=1,
	parameter dw=14,
	parameter delta=16
) (
	input uclk1,  // unknown clock 1
	input uclk2,  // unknown clock 2
	input uclk2g,
	input sclk,   // sampling clock
	input rclk,   // readout clock (data transfer, local bus)
	input [dw-1:0] adv,  // make adv a runtime variable
	output err,
	// the following are in rclk domain
	output [dw-2:0] phdiff_out,
	output [dw-1:0] vfreq_out,
	output err_ff
);
// For the default dw=14 case, the previous 32-bit status word
// (fully in the rclk domain) can be constructed externally as
//   wire [31:0] status_out = {err_ff, vfreq_out, 4'b0, phdiff_out};
//   32                     =  1     + 14       + 4   + 13

// XXX vfreq_out could have extra msbs added by unwrapping, or better still,
// adding higher-order bits to phaset.

// Two phase trackers
wire [dw-1:0] phaset_out1, phaset_out2;
wire fault1, fault2;
phaset #(.order(order1), .dw(dw), .delta(delta)) track1(
	.uclk(uclk1), .uclkg(1'b1), .sclk(sclk), .adv(adv),
	.phase(phaset_out1), .fault(fault1));
phaset #(.order(order2), .dw(dw), .delta(delta)) track2(
	.uclk(uclk2), .uclkg(uclk2g), .sclk(sclk), .adv(adv),
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

reg_tech_cdc err_cdc(.I(err_r), .C(rclk), .O(err_ff));
endmodule
