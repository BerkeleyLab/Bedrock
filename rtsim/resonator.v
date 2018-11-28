`timescale 1ns / 1ns

// Propagate between 5 and 512 resonators, two clock cycles per resonator.
// Timing of input drive signal, and output position signal, are relative
// to the start pulse.

// Executes z * v_o = v_o + (a-1) * v_o + v_i
// where all quantities are complex, and a is the pole location.  Nominal
// configuration for second-order low-pass uses real number input, and
// the imaginary component of v_o is the output.  More precisely, it
// executes z * v_o = v_o + (wd * v_o + v_i) * 4^(scale-9)
// where wd = (a-1) * 4^(7-scale) and scale is between 0 and 7.
// The low-frequency gain in the low-pass configuration is -imag(1/wd)

// Considered z * v_o = v_o + (a-1) * (v_o + v_i), which has a simpler
// expression for gain, but rejected it because that would break the
// real/imaginary setup of a low-pass filter.

// The drive signal for mode 1, using coefficients kept at memory locations
// 2 and 3, needs to show up 12 and 13 cycles after the start pulse.
// The output will arrive 4 cycles after the drive.  These relations still
// hold if they pass over the following start pulse; everything is circular.
// But the pipeline length of 10 means the minimum number of resonators is 5.
// Of course, just because a resonator is in memory and gets processed,
// doesn't mean you have to feed it non-zero drive, or look at the result.

// Two 18x18 multipliers here; dwarfed by the multipliers used to
// compute dot products.  One set to convert physical excitation
// sources to the per-mode drive signal, and another set to convert
// from the abstract mode coordinates to the physical responses
// (cavity electrical mode frequency shifts).

// The size and speed of this module is such that it might be able to
// handle simulation of a whole croymodule at once (8 cavities) in the
// XC7A200T of an AC701 board.
module resonator(
	input clk,
	input start,  // provide every (number of modes)*2 clock cycles
	input signed [17:0] drive,
	output signed [17:0] position,
	output clip,
	input [20:0] prop_const,  // external
	output [9:0] prop_const_addr  // external
);

// pcw sets the size of state and coefficient memory.
// The number of resonator modes processed is 2^(pcw-1), since
// one mode takes two memory locations and two cycles.
// The time between start pulses should not exceed 2^pcw cycles.
// For now pcw must match width of prop_const_addr.
parameter pcw = 10;

reg [pcw-1:0] pc=0;
always @(posedge clk) pc <= start ? 0 : pc+1;
wire iq = pc[0];

// Delay from register read to register write
wire [pcw-1:0] pc_d;
reg_delay #(.dw(pcw),.len(11))
	pc_del(.clk(clk), .reset(1'b0), .gate(1'b1), .din(pc), .dout(pc_d));

// State vector memory
// Scaled fixed-point such that full-scale is 1.0
wire signed [35:0] ab_out0;
wire signed [35:0] ab_in;  // computed later
dpram #(.dw(36), .aw(pcw)) ab(.clka(clk), .clkb(clk),
	.addra(pc_d), .dina(ab_in), .wena(1'b1),
	.addrb(pc), .doutb(ab_out0));

// Result from state propagation constant memory (host-writable)
wire signed [17:0] wd_out0 = prop_const[17:0];
wire [2:0] scale0 = prop_const[20:18];
assign prop_const_addr = pc;

// Pipeline
reg signed [35:0] ab_out=0, ab_out1=0;
reg signed [17:0] wd_out=0, wd_out1=0;
reg [2:0] scale=0, scale1=0;
always @(posedge clk) begin
	ab_out1 <= ab_out0;  ab_out <= ab_out1;
	wd_out1 <= wd_out0;  wd_out <= wd_out1;
	scale1  <= scale0;   scale  <= scale1;
end

// Complex multiply, same as matrix [-d k;-k -d]
wire signed [17:0] mul_result;
vectormul mul(.clk(clk), .gate_in(1'b1), .iq(iq),
	.x(ab_out[35:18]), .y(wd_out), .z(mul_result));
// I want to take SAT out of vectormul to save a useless
// pipelining step or two, see sub_mul in lp1.v

// Add in the drive term, itself a dot-product of excitation sources
reg signed [18:0] foo_result=0;
always @(posedge clk) foo_result <= mul_result + drive;

// Binary scaling
wire [2:0] scale_d;
reg_delay #(.dw(3),.len(5))
	sc_del(.clk(clk), .reset(1'b0), .gate(1'b1), .din(scale), .dout(scale_d));

reg signed [32:0] shf_result=0;
always @(posedge clk) case (scale_d)
	3'd0: shf_result <= foo_result;
	3'd1: shf_result <= foo_result <<< 2;
	3'd2: shf_result <= foo_result <<< 4;
	3'd3: shf_result <= foo_result <<< 6;
	3'd4: shf_result <= foo_result <<< 8;
	3'd5: shf_result <= foo_result <<< 10;
	3'd6: shf_result <= foo_result <<< 12;
	3'd7: shf_result <= foo_result <<< 14;
endcase

// Combine original state vector with delta
wire signed [35:0] ab_del_out;
reg_delay #(.dw(36),.len(6))
	ab_del(.clk(clk), .reset(1'b0), .gate(1'b1), .din(ab_out), .dout(ab_del_out));
reg signed [36:0] sum_result=0;
always @(posedge clk) sum_result <= ab_del_out + shf_result;

// Saturate result
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
reg signed [35:0] sat_result=0;
reg clip_r=0;
always @(posedge clk) begin
	sat_result <= `SAT(sum_result,36,35);
	clip_r <= ~(~|sum_result[36:35] | &sum_result[36:35]);
end

assign ab_in = sat_result;
assign position = sat_result[35:18];
assign clip = clip_r;

endmodule
