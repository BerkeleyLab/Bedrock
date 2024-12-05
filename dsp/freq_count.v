// Synthesizes to 86 slices at 312 MHz in XC3Sxxx-4 using XST-8.2i
//  (well, that's just the unknown frequency input; max sysclk is 132 MHz)

`timescale 1ns / 1ns

module freq_count #(
	// Default configuration useful for input frequencies < 2*sysclk
	parameter glitch_thresh=2,
	parameter refcnt_width=24,
	parameter freq_width=28,
	parameter initv=0
) (
	// input clocks
	input sysclk,  // timespec 8.0 ns
	input f_in,  // unknown input

	// outputs in sysclk domain
	output reg [freq_width-1:0] frequency,
	output freq_strobe,
	output reg [15:0] diff_stream,
	output reg diff_stream_strobe,
	// glitch_catcher can be routed to a physical pin to trigger
	// a 'scope; see glitch_thresh parameter above
	output reg glitch_catcher
);

initial begin
	frequency=initv;
	diff_stream=0;
	diff_stream_strobe=0;
	glitch_catcher=0;
end

// Reference counter
// may or may not be synchronized between instances
reg [refcnt_width-1:0] refcnt=0;
reg ref_strobe=0, stream_strobe=0;
always @(posedge sysclk) begin
	{ref_strobe, refcnt} <= refcnt + 1;
	stream_strobe <= refcnt[1:0] == 0;
end

wire [3:0] xcount;  // per-sysclk count of f_in edges
wire [freq_width-1:0] frequency_w;
freq_gcount #(
	.freq_width(freq_width),
	.initv(initv)
) work (
	.sysclk(sysclk), .f_in(f_in),
	.g_in(1'b1),  // this is the whole point!
	.ref_strobe(ref_strobe),
	.frequency(frequency_w), .freq_strobe(freq_strobe),
	.xcount(xcount)
);

// Nobody except some ancient USB debugging ever used this.
// It's harmless; if you don't attach to the diff_stream,
// diff_stream_strobe, or glitch_catcher ports, it will all
// just disappear in synthesis.
//
// Make xcount available to stream to host at 24 MByte/sec, which was
// especially interesting when reprogramming a AD9512 clock divider
// on a LLRF4 board.
// It might also be possible to histogram xcount.
reg [15:0] stream=0;
always @(posedge sysclk) begin
	if (xcount > glitch_thresh) glitch_catcher <= ~glitch_catcher;
	stream <= {stream[11:0], xcount};  // assumes freq_gcount gw=4
end

// Latch/pipeline one more time to perimeter of this module
always @(posedge sysclk) begin
	diff_stream <= stream;
	diff_stream_strobe <= stream_strobe;
	frequency <= frequency_w;
end

endmodule
