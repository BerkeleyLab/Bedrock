// Appends 32-bit Ethernet CRC to the end of a packet
// Also inserts GMII preamble
//
// The cycle-by-cycle timing definition for these tasks
// comes from the raw_s (short) and raw_l (long) strobes;
// raw_s is valid just for the (incoming) packet data.
// raw_l is also valid for a few cycles before, and 4 cycles after, that.
module ethernet_crc_add(
	input clk,
	input ce,
	input raw_s,
	input raw_l,
	input [7:0] raw_d,
	output opack_s,
	output [7:0] opack_d
);

// Strobes are easy
reg raw_s_d=0, raw_l_d=0;
always @(posedge clk) if (ce) begin
	raw_s_d <= raw_s;
	raw_l_d <= raw_l;
end
wire first_crc = raw_s & ~raw_s_d;
wire trail = raw_s_d & ~raw_s;
wire gate_crc;
wire out_crc_sel;

// Instantiation
wire [7:0] crc_out;
crc8e_guts #(.wid(32)) crc8e(.clk(clk), .gate(gate_crc),
	.first(first_crc), .d_in(out_crc_sel ? ~crc_out : raw_d),
	.d_out(crc_out), .zero());

// Multiplexing
reg [1:0] crc_cnt=0;
reg [7:0] opack_r=0;
assign gate_crc = ce & (raw_s | raw_s_d | (crc_cnt != 0));
assign out_crc_sel = trail | (|crc_cnt);
always @(posedge clk) if (ce) begin
	crc_cnt <= out_crc_sel ? crc_cnt+1 : 0;
	opack_r <= out_crc_sel ? crc_out : raw_s ? raw_d : 8'h55;
end
assign opack_d = first_crc ? 8'hd5 : opack_r;
assign opack_s = raw_l | raw_l_d;

endmodule
