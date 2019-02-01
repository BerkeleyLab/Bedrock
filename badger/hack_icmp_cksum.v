// Subtracts 0x800 from an ICMP checksum
// Sounds easy, right?  But actually pretty tricky to correctly
// handle 16-bit one's-complement arithmetic on data flying by 8-bits
// at a time.  Tricky enough that Du got it wrong in icmp_rx.v;
// that code gets the right checksum only 31/32 of the time.
// Quoting RFC 792:
//    The checksum is the 16-bit ones's [sic] complement of the one's
//    complement sum of the ICMP message starting with the ICMP Type.

// Output is delayed two cycles from input.
// kick needs to be asserted on the second of the two cycles
//   with the checksum at the input.

module hack_icmp_cksum(
	input clk,
	input kick,
	input [7:0] idat,
	output [7:0] odat
);

// Precompute the all-ones condition
wire ones_i = &idat;
reg ones_r=0;
always @(posedge clk) ones_r <= ones_i;
wire all_ones = ones_i & ones_r;

// Insert modified checksum into stream
wire [15:0] x3;
reg [7:0] dat1=0, dat2=0;
always @(posedge clk) begin
	dat1 <= kick ? x3[7:0] : idat;
	dat2 <= kick ? x3[15:8] : dat1;
end

// 16-bit checksum arithmetic
// Because of the extra inversion, we really add 0x800.
wire [15:0] x0 = {dat1, idat};
wire [15:0] x1 = {x0[10:0], x0[15:11]};  // rotate right 11 bits
wire [15:0] x2 = x1 + 1 + all_ones;
assign x3 = {x2[4:0], x2[15:5]};  // rotate left 11 bits

assign odat = dat2;

endmodule
