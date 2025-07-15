`timescale 1ns / 1ns
// Synthesizes to 17 slices at 155 MHz in XC3Sxxx-4 using XST-10.1i

// Transform a raw phase difference (-pi to pi) into a control signal
// for a PLL.  Uses internal state to generate the right full-scale
// DC signal when the frequencies are mismatched.  In the final,
// locked-at-zero-phase state, the output equals the input.

// Subtle API change from old pdetect: when strobe_in is not set,
// the output follows the input exactly.

// Yet another API change: new input "reset", only used when strobe_in
// is set, resets the state machine to unwound.

module pdetect #(
	parameter w=17
) (
	input clk,
	input [w-1:0] ang_in,
	input strobe_in,
	input reset,
	output reg [w-1:0] ang_out,
	output reg strobe_out
);

// coding is important, see usage of next bits below
reg [1:0] state=0;
`define S_LINEAR 0
`define S_CLIP_P 2
`define S_CLIP_N 3

initial ang_out=0;
initial strobe_out=0;

reg [1:0] prev_quad=0;
wire [1:0] quad = ang_in[w-1:w-2];
wire trans_pn = (prev_quad==2'b01) & (quad==2'b10);
wire trans_np = (prev_quad==2'b10) & (quad==2'b01);

reg [1:0] next=0;
always @(*) begin
	next=state;
	if (trans_pn & (state==`S_LINEAR)) next=`S_CLIP_P;
	if (trans_np & (state==`S_LINEAR)) next=`S_CLIP_N;
	if (trans_pn & (state==`S_CLIP_N)) next=`S_LINEAR;
	if (trans_np & (state==`S_CLIP_P)) next=`S_LINEAR;
	if (reset) next=`S_LINEAR;
end

wire [w-1:0] clipv = {next[0],{w-1{~next[0]}}};
always @(posedge clk) begin
	if (strobe_in) begin
		prev_quad <= quad;
		state <= next;
	end
	ang_out <= (next[1] & strobe_in & ~reset) ? clipv : ang_in;
	strobe_out <= strobe_in;
end

endmodule
