// High-speed cycle counter

// This module attaches to the slow readout bus used in many
// LBNL DAQ builds. It provides a 59-bit cycle counter (since chip boot),
// and an optional timestamp capture register.

// The 8-bit-wide shift-register-style output is ready to be merged
// in a "slow" DSP data stream, LSB-first.  Sorry about the byte-order,
// but it's intrinsic to the mechanism used.

// Synthesizes to 54 LUTs and 31 Flip flops at 150 MHz in XC3S1000-5 with XST 12.1 (aux_reg=0)
// Synthesizes to 101 LUTs and 65 Flip flops at 150 MHz in XC3S1000-5 with XST 12.1 (aux_reg=1)
// 59-bit counter will wrap every 182 years if clocked at 100 MHz.
`timescale 1ns / 1ns
module timestamp(
	input clk,  // timespec 6.6 ns
	// aux_ ports are only useful if parameter aux_reg is 1
	input aux_trig,
	output aux_skip,
	input slow_op,
	input slow_snap,
	input [7:0] shift_in,
	output [7:0] shift_out
);

// Re-use some ideas from SNS

// Data bus width, used to make the testing process shorter and more believable.
parameter dw=8;
parameter aux_reg=0;

reg [2:0] fast=0;
reg [dw-1:0] count_loop=0;
reg c_out=0;
wire [dw-1:0] count_out;
wire c_in = (fast==0) ? 1 : c_out;
always @(posedge clk) begin
	fast <= fast+1;
	{c_out,count_loop} <= count_out + c_in;
end

reg_delay #(.dw(dw), .len(7))
	count(.clk(clk), .reset(1'b0), .gate(1'b1), .din(count_loop), .dout(count_out));

// Can snapshot fast anytime.  Have to wait for the next cycle of
// fast sequencing from 0 through 7 before the rest of the counter
// state can be read out
reg pending=0, sending=0, grab_fast=0;
always @(posedge clk) begin
	grab_fast <= slow_op & slow_snap;
	if (fast==7) pending <= 0;
	if (slow_op & slow_snap) pending <= 1;
	if (fast==7) sending <= pending;
	if (fast==6) sending <= 0;
end
wire [dw-1:0] fast_pad={fast,{dw-3{1'b0}}};
wire [dw-1:0] shift_in2;  // output of aux subsystem
wire [dw-1:0] snap_in = grab_fast ? fast_pad : (slow_op&~slow_snap) ? shift_in2 : count_out;
wire snap_shift=grab_fast|(slow_op&~slow_snap)|sending;
wire [dw-1:0] snap_out;
reg_delay #(.dw(dw), .len(8))
	s1(.clk(clk), .reset(1'b0), .gate(snap_shift), .din(snap_in), .dout(snap_out));

// Second snapshot register
// If aux_reg is a constant 0 at compile-time, this will get optimized away
reg abusy=0, axmit=0, astored=0;
reg apending=0, asending=0, agrab_fast=0;
always @(posedge clk) begin
	agrab_fast <= aux_trig & ~abusy;
	if (aux_trig) abusy <= 1;
	if (fast==7) apending <= 0;
	if (aux_trig & ~abusy) apending <= 1;
	if (fast==7) asending <= apending;
	if (fast==6) asending <= 0;
	if ((fast==6)&asending) astored<=1;
	if (astored&slow_op&slow_snap) begin astored<=0; axmit<=1; end
	if (axmit&slow_op&slow_snap) begin axmit<=0; abusy<=0; end
end
wire [dw-1:0] ashiftd;  // hold shift register data in parallel with aux slot
reg_delay #(.dw(dw), .len(8))
	aslow(.clk(clk), .reset(1'b0), .gate(slow_op), .din(shift_in[dw-1:0]), .dout(ashiftd));
wire [dw-1:0] asnap_in = agrab_fast ? fast_pad : count_out;
wire asnap_shift=agrab_fast|asending|(axmit&slow_op&~slow_snap);
wire [dw-1:0] asnap_out;  // shift register fills with time info
reg_delay #(.dw(dw), .len(8))
	a1(.clk(clk), .reset(1'b0), .gate(asnap_shift), .din(asnap_in), .dout(asnap_out));
// Keep track of the first 8 shift commands
reg [2:0] ascnt=0;
reg apost8=0;
always @(posedge clk) begin
	if (slow_op&slow_snap) begin ascnt<=0; apost8<=0; end
	if (slow_op&~slow_snap&~apost8) ascnt<=ascnt+1;
	if (slow_op&~slow_snap&(ascnt==7)) apost8<=1;
end
// Note dependence on aux_reg
// Always skips in the non-aux_reg case
assign aux_skip = aux_reg ? (aux_trig & abusy) : aux_trig;
assign shift_in2 = aux_reg ? (apost8 ? ashiftd : axmit ? asnap_out : 0) : shift_in;

// Output of this module is simply the output of the above shift register
// Making an explicit copy like this avoids a warning when dw != 8
assign shift_out=snap_out;

// More-or-less equivalent to
// define SLOW_SR_DATA { time1, time2, time3, time4, atime1, atime2, atime3, atime4 }
// but uses far fewer resources

endmodule
