// Digital phase-locked-loop tracker

// At least in this application, the sampling clock is not phase-locked
// to the clocks of interest.  So a binary phase accumulator is as good
// as any, and it makes the arithmetic for subtracting the two results
// (from the two unknown clocks) easy.

`timescale 1ns / 1ns

module phaset #(
	parameter order=1,
	parameter dw=14,
	parameter delta=16
) (
	input uclk,
	input uclkg,
	input sclk,
        input [dw-1:0] adv,
	output [dw-1:0] phase,
	output fault  // single cycle
);

// _Still_ draw analogy to the AD9901
// Generalize to a Johnson counter
reg [order-1:0] ishr=0;
always @(posedge uclk) if (uclkg) ishr <= (ishr << 1) | {{order-1{1'b0}},~ishr[order-1]};
wire capture;  reg_tech_cdc capture_cdc(.I(ishr[0]), .C(sclk), .O(capture));

// Test bench fails for some initial phase_r values between 14900 and 15050.
// In that case the fault output signals the problem.
reg [dw-1:0] osc=0, acc=0, phase_r=0;
reg fault_r=0;
wire msb = acc[dw-1];
wire nsb = acc[dw-2];
wire peak = acc[dw-2] ^ acc[dw-3];  // peak of virtual sine wave
wire move = capture != msb;
wire dir  = ~nsb;
wire dn = move &  dir;
wire up = move & ~dir;
always @(posedge sclk) begin
	if (move) phase_r <= phase_r + (dir ? -delta : delta);
	fault_r <= move & peak;
	osc <= osc + adv;
	acc <= osc + phase_r;
end
assign phase = phase_r;
assign fault = fault_r;

endmodule
