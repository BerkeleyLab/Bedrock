// By default, the following three modules take one or two 18-bit signed inputs,
// and produce a 22-bit signed output in a single clock cycle.
// Scaling comments assume each number is interpreted as in the range [-1:1],

// multiply
// r = a * b / 2
// Internally, expect to use 18-bit signed inputs to the hardware multiplier,
// matching the capabilities of Xilinx, Altera, Lattice, and Gowin chips.
// Configuring for 24-bit signed multiplication still works OK with Xilinx
// DSP48E1 and Vivado, where it combines two 18x25 multipliers and still
// makes reasonable timing.
module sf_mul #(
	parameter dw=18,
	parameter mw=18
) (
	input clk,
	input ce,  // clock enable
	// input ports
	input signed [dw-1:0] a,
	input signed [dw-1:0] b,
	// result ports
	output [dw+3:0] r
);

reg signed [2*mw-1:0] r1;  // full 36-bit result
wire signed [mw-1:0] a_trunc = a[dw-1:dw-mw];
wire signed [mw-1:0] b_trunc = b[dw-1:dw-mw];
always @(posedge clk) if (ce) begin
	r1 <= a_trunc * b_trunc;
end
assign r = r1[2*mw-1:2*mw-4-dw];
endmodule

// add or subtract
// r = (a +/- b) / 2
module sf_add #(
	parameter dw=18
) (
	input clk,
	input ce,  // clock enable
	// input ports
	input signed [dw-1:0] a,
	input signed [dw-1:0] b,
	input sub,
	// result ports
	output [dw+3:0] r
);

reg signed [dw:0] r1;
always @(posedge clk) if (ce) begin
	r1 <= sub ? (a-b) : (a+b);
end
assign r = {r1[dw],r1,2'b0};
endmodule

// approximate inverse, to start iterative refinement
// (1/a) / 256
// See inver1.py for supporting theory,
// and cgen_lib.py function full_inv for iteration rule
module sf_inv #(
	parameter dw=18
) (
	input clk,
	input ce,  // clock enable
	// input ports
	input signed [dw-1:0] a,
	// output ports
	output [dw+3:0] r
);

localparam iscale = 9;  // number of non-sign bits to use in LUT
wire [iscale-1:0] abs_a = a[dw-1] ? ~a[dw-2:dw-1-iscale] : a[dw-2:dw-1-iscale];
reg [iscale:0] r1=0;
reg sign_a=0;
always @(posedge clk) if (ce) begin
	sign_a <= a[dw-1];
	casez (abs_a)
	// positive numbers
	//  r=min(floor(16./[0:15]*16/4+0.5),15);
	//  printf('\t%d: r1 <= %d;\n',[[0:15]; r])
	// 2.^(-floor(log2([0:255]/256))-1)
	// In theory can be parameterized with a for loop;
	// this version hard-coded for the case iscale == 8.
	9'b11???????: r1 <= 2;
	9'b10???????: r1 <= 3;
	9'b011??????: r1 <= 4;
	9'b010??????: r1 <= 6;
	9'b0011?????: r1 <= 8;
	9'b0010?????: r1 <= 12;
	9'b00011????: r1 <= 16;
	9'b00010????: r1 <= 24;
	9'b000011???: r1 <= 32;
	9'b000010???: r1 <= 48;
	9'b0000011??: r1 <= 64;
	9'b0000010??: r1 <= 96;
	9'b00000011?: r1 <= 128;
	9'b00000010?: r1 <= 192;
	9'b000000011: r1 <= 256;
	9'b000000010: r1 <= 384;
	9'b000000001: r1 <= 512;
	9'b000000000: r1 <= 1023;
	endcase
end
assign r = {sign_a, (sign_a ? ~r1 : r1), {(dw+4-iscale-2){sign_a}}};
//  (1 + (iscale+1) + (dw+4-iscale-2) = dw+4
endmodule

// put the above modules together, with saturating shifter
// Now the output width matches the input width of 18 bits
module sf_alu #(
	parameter dw=18,
	parameter mw=18  // see sf_mul
) (
	input clk,
	input ce,  // clock enable
	// input ports
	input signed [dw-1:0] a,
	input signed [dw-1:0] b,
	input [2:0] op,
	input [1:0] sv,
	// result ports
	output signed [dw-1:0] r,
	output valid_o,
	output sat_happened
);

reg vo_mul=0, vo_add=0, vo_inv=0;
always @(posedge clk) if (ce) begin
	vo_mul <= op==4;
	vo_add <= op[2:1]==3;
	vo_inv <= op==5;
end
wire signed [dw+3:0] r_mul, r_add, r_inv;
sf_mul #(.dw(dw), .mw(mw)) mul(.clk(clk), .ce(ce), .a(a), .b(b),              .r(r_mul));
sf_add #(.dw(dw)) add(.clk(clk), .ce(ce), .a(a), .b(b), .sub(op[0]), .r(r_add));
sf_inv #(.dw(dw)) inv(.clk(clk), .ce(ce), .a(a),                     .r(r_inv));

reg valid_s=0, valid_r=0;
reg signed [dw+3:0] shf;
reg signed [dw-1:0] sat;
wire signed [dw+3:0] mux = vo_mul ? r_mul : vo_add ? r_add : r_inv;
reg sat_happened_r=0;
always @(posedge clk) if (ce) begin
	// multiplexer and shifter
	valid_s <= vo_mul|vo_add|vo_inv;
	case (sv)
		0: shf <= {{3{mux[dw+3]}},mux[dw+3:3]};
		1: shf <= {{2{mux[dw+3]}},mux[dw+3:2]};
		2: shf <= {{1{mux[dw+3]}},mux[dw+3:1]};
		3: shf <= {            mux      };
	endcase
	// saturater
	valid_r <= valid_s;
`define UNSAT(x,old,new) (~|x[old:new] | &x[old:new])
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
	sat <= `SAT(shf,dw+3,dw-1);
	sat_happened_r <= ~`UNSAT(shf,dw+3,dw-1);
end
assign r = sat;
assign valid_o = valid_r;
assign sat_happened = valid_r & sat_happened_r;

`undef SAT
`undef UNSAT

endmodule

// ALU and register file, no instruction sequencing
module sf_main #(
	parameter pw = 18,  // port width
	parameter extra = 4,  // extra guard bits that appear in registers and some arithmetic, but maybe not multiplier inputs
	parameter mw = 18  // multiplier width, see sf_mul
) (
	input clk,
	input ce,  // clock enable
	input [20:0] inst,  // consumes 21 bits of instruction per cycle
	input signed [pw-1:0] meas,  // measurements from radio
	// Results
	output                 ab_update,
	output signed [pw-1:0] a_o,
	output signed [pw-1:0] b_o,
	output                 cd_update,
	output signed [pw-1:0] c_o,
	output signed [pw-1:0] d_o,
	// Monitoring only, probably superfluous
	output signed [pw+extra-1:0] trace,
	output collide_o,
	output stray_o,
	output discard_o,
	output sat_happened
);

// Instruction word "decoding"
// Controller should set wa and set during cycles when meas comes in.
//  op
//   0  NOP
//   1  write results to external hardware (a_o, b_o)
//   2  write results to external hardware (c_o, d_o)
//   3  -
//   4  mul
//   5  inv
//   6  add
//   7  sub
// Pipelining is very simple:
//  cycle  valid fields    name
//    1   ra_a,  ra_b     read
//    2   op              operate
//    3   sv              mux/shift
//    4   -               saturate
//    5   wa              writeback
// The new value of a destination register is first readable at cycle 6.
// The collision detection logic is completely superfluous.
// The stray and discard logic is mostly superfluous.
wire [4:0] ra_a = inst[4:0];
wire [4:0] ra_b = inst[9:5];
wire [4:0] wa = inst[14:10];
wire [2:0] op = inst[17:15];
wire [1:0] sv = inst[19:18];
wire       set = inst[20];

localparam dw = pw + extra;
integer scale = 1 << extra; // Not used here, but helps test bench display numbers properly

// Register file: one writer, two readers
wire signed [dw-1:0] alu_out;
wire signed [dw-1:0] d_in = set ? {meas,{extra{1'b0}}} : alu_out;
wire we_a;
wire we = we_a | set;
wire wa_zero = ~(|wa);
(* ram_style = "distributed" *) reg signed [dw-1:0] rf_a [31:0];
(* ram_style = "distributed" *) reg signed [dw-1:0] rf_b [31:0];
reg signed [dw-1:0] a=0, b=0;
always @(posedge clk) if (ce) begin
	if (we) rf_a[wa] <= d_in;
	if (we) rf_b[wa] <= d_in;
	a <= rf_a[ra_a];
	b <= rf_b[ra_b];
end

sf_alu #(.dw(dw), .mw(mw)) alu(.clk(clk), .ce(ce), .a(a), .b(b), .op(op), .sv(sv),
	.r(alu_out), .valid_o(we_a),
	.sat_happened(sat_happened));

// make values available to outside world
// take most significant bits
reg signed [pw-1:0] a_out=0, b_out=0;
reg ab_u=0;
always @(posedge clk) if (ce & (op==1)) begin
	a_out <= a[dw-1:extra];
	b_out <= b[dw-1:extra];
	ab_u <= 1;
end else ab_u <= 0;
assign a_o = a_out;
assign b_o = b_out;
assign ab_update = ab_u;

// make values available to outside world
// take most significant bits
reg signed [pw-1:0] c_out=0, d_out=0;
reg cd_u=0;
always @(posedge clk) if (ce & (op==2)) begin
	c_out <= a[dw-1:extra];
	d_out <= b[dw-1:extra];
	cd_u <= 1;
end else cd_u <= 0;
assign c_o = c_out;
assign d_o = d_out;
assign cd_update = cd_u;

assign trace = d_in;
assign collide_o = we_a & set;
assign stray_o = ~wa_zero & ~we;
assign discard_o = wa_zero & we;
endmodule
