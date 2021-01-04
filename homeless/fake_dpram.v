// Fake two independent R/W ports using a single dpram
// Cheaters' full DPRAM
//
// Stupidly simple single-clock-domain bus arbitration.
// Neither port is allowed to hog the bus, and port B has
// one extra cycle of read latency, two instead of one.
//
// Presumably you could make a leaner implementation of this
// by instantiating a vendor-primitive true dual-port block
// memory, and adding another register to the port 2 output.
// But I don't think there's a portable way to write such
// a thing for inference, and in any event it wouldn't work
// with simpler DPRAM primitives like those in the iCE40.
//
// In principle, this implementation doesn't need the
// read and write addresses to match within each port.
// But our use cases don't require separating them, and
// doing so wouldn't be consistent with the previous paragraph.
//
// Timing errors detected and reported on error output port
// are not latched or counted here.

`timescale 1ns / 1ns

module fake_dpram #(
	parameter aw=9,
	parameter dw=8
) (
	input clk,
	// Port 1
	input [aw-1:0] addr1,
	input [dw-1:0] din1,
	output [dw-1:0] dout1,  // 1-cycle latency
	input wen1,
	input ren1,
	// Port 2
	input [aw-1:0] addr2,
	input [dw-1:0] din2,
	output [dw-1:0] dout2,  // 2-cycle latency
	input wen2,
	input ren2,
	// Status: violation of the don't-hog-the-bus rule
	output error
);

// register a couple inputs
reg [aw-1:0] addr2_d=0;
reg [dw-1:0] din2_d=0;
reg wen1_d=0, ren1_d=0, wen2_d=0, ren2_d=0;
always @(posedge clk) begin
	addr2_d <= addr2;
	din2_d <= din2;
	wen1_d <= wen1;
	ren1_d <= ren1;
	wen2_d <= wen2;
	ren2_d <= ren2;
end

wire [dw-1:0] filler;
`ifdef SIMULATE
assign filler = {dw{1'bx}};
`else
assign filler = {dw{1'b0}};
`endif

// A port for writing
wire [aw-1:0] addra = wen1 ? addr1 : wen2 ? addr2 : addr2_d;
wire [dw-1:0] dina = wen1 ? din1 : wen2 ? din2 : din2_d;
wire wena = wen1 | wen2 | (wen1_d & wen2_d);
// B port for reading
wire [aw-1:0] addrb = ren1 ? addr1 : ren2 ? addr2 : addr2_d;

// dpram has no explicit read-able port, it just reads every cycle
wire [dw-1:0] doutb;
dpram #(.aw(aw), .dw(dw)) mem(
	.clka(clk), .clkb(clk),
	.addra(addra), .dina(dina), .wena(wena),
	.addrb(addrb), .doutb(doutb)
);

// Port 1 output is easy
assign dout1 = ren1_d ? doutb : filler;

// Port 2 output takes some extra registering
reg [dw-1:0] doutb_d=0;
reg ren1_dd=0, ren2_dd=0;
always @(posedge clk) begin
	doutb_d <= doutb;
	ren1_dd <= ren1_d;
	ren2_dd <= ren2_d;
end
assign dout2 = ren2_dd ? (ren1_dd ? doutb : doutb_d) : filler;

// Report an error if the "no hogging the bus" rule is violated,
// even if there is no harm this time.
assign error = (wen1 & wen1_d) | (ren1 & ren1_d) | (wen2 & wen2_d) | (ren2 & ren2_d);

endmodule
