`timescale 1ns / 1ns

// Specialized set-point slew-rate limit for mp_proc.
// Let mp_proc continue to handle attachment to localbus via newad.
// Be careful to match mp_proc timing, and to wrap set_p but not set_m
module slew_xarray #(
	parameter dw=18
) (
	input clk,
	input enable,  // when zero, just passes through
	input signed [dw-1:0] setmp,  // from localbus
	output signed [dw-1:0] setmp_l,  // to application, slew-rate-limited
	input setmp_addr,
	input step,  // can wire to 1 for full-speed slew
	output [1:0] motion
);
// Note that mp_proc does
// assign setmp_addr = {1'b0, ~state[0]};
// We "know" that, and only take in the lsb.
reg [dw-1:0] current=0, prev=0;
reg [dw:0] diff=0;
reg match=1, enable1=0;
reg motionm=0, motionp=0;
wire wrap = setmp_addr;  // verified in simulation
wire dir = wrap ? diff[dw-1] : diff[dw];
wire step1 = enable & step & ~match;
always @(posedge clk) begin
	diff <= setmp - current;
	match <= setmp == current;
	// following line should synthesize to a single bank of addsub
	current <= dir ? prev-step1 : prev+step1;
	prev <= enable ? current : setmp;
	enable1 <= enable;
	if (~setmp_addr) motionm <= ~match;
	if ( setmp_addr) motionp <= ~match;
end

assign setmp_l = current;
assign motion = {motionm, motionp};

endmodule
