// Converts binary input to serial decimal output
// Conversion starts when triggered by the active high load port.
// Output nibbles are emitted lsb-first, would need to be
// reversed before they could be considered nicely human-readable.
// Output nibbles are valid when gated by nstrobe output.
module b2d #(
	parameter dw=16,  // input data width in bits
	parameter sim_mode=0
) (
	input clk,
	input [dw-1:0] bdata,
	input load,
	output [3:0] nibble,
	output nstrobe
);

// Hold the data in a shift register
reg [dw-1:0] sr;
wire shiftin;
always @(posedge clk) sr <= load ? bdata : {sr[dw-2:0], shiftin};
wire shiftout = sr[dw-1];

// Need to know how often the word repeats
reg [4:0] bcnt;
wire bdone = load || bcnt == 0;
always @(posedge clk) bcnt <= bdone ? dw-1 : bcnt-1;

// Actual work
// Get the basics working using 10
// can optimize to 5*2 later if the synthesizer can't optimize sufficiently
reg [3:0] accum;
wire [4:0] accum5 = {accum, shiftout};
wire got_one = accum5 >= 10;
wire [3:0] accum_sub = got_one ? accum5 - 10 : accum5;
always @(posedge clk) accum <= bdone ? 0 : accum_sub;
assign shiftin = got_one;

// Construct output
assign nstrobe = bcnt == 0;
assign nibble = (nstrobe | !sim_mode) ? accum_sub : 4'bx;

endmodule
