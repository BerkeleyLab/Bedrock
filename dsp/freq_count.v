// Synthesizes to 86 slices at 312 MHz in XC3Sxxx-4 using XST-8.2i
//  (well, that's just the sampling clock; max usbclk is 132 MHz)

`timescale 1ns / 1ns

module freq_count #(
	// Default configuration useful for input frequencies < 96 MHz
	parameter glitch_thresh=2,
	parameter refcnt_width=24,
	parameter initv=0
) (
	// input clocks
	input clk,  // timespec 8.0 ns
	input usbclk,

	// outputs in usbclk domain
	output reg [27:0] frequency,
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

// four-bit Gray code counter on the input signal
// http://en.wikipedia.org/wiki/Gray_code
localparam gw=4;
reg [gw-1:0] gray1=0;
// The following three expressions compute the next Gray code based on
// the current Gray code.  Vivado 2016.1, at least, is capable of reducing
// them to the desired four LUTs when gw==4.
wire [gw-1:0] bin1 = gray1 ^ {1'b0, bin1[gw-1:1]};  // Gray to binary
wire [gw-1:0] bin2 = bin1 + 1;  // add one
wire [gw-1:0] gray_next = bin2 ^ {1'b0, bin2[gw-1:1]};  // binary to Gray
always @(posedge clk) gray1 <= gray_next;

// transfer that Gray code to the measurement clock domain
reg [3:0] gray2=0, gray3=0;
always @(posedge usbclk) begin
	gray2 <= gray1;
	gray3 <= gray2;
end

wire [3:0] bin3 = gray3 ^ {1'b0, bin3[3:1]}; // convert Gray to binary

reg [3:0] bin4=0, bin5=0, diff1=0;
always @(posedge usbclk) begin
	bin4 <= bin3;
	bin5 <= bin4;
	diff1 <= bin4-bin5;
	if (diff1 > glitch_thresh) glitch_catcher <= ~glitch_catcher;
end

// I'd like to histogram diff1, but for now just accumulate it.
// Also make it available to stream to host at 24 MByte/sec, might be
// especially interesting when reprogramming the AD9512.
// 48 MHz usbclk / 2^24 = 2.861 Hz update
reg [27:0] accum=0, result=initv;
reg [refcnt_width-1:0] refcnt=0;
reg ref_carry=0;
reg [15:0] stream=0;
reg stream_strobe=0;
always @(posedge usbclk) begin
	{ref_carry, refcnt} <= refcnt + 1;
	if (ref_carry) result <= accum;
	accum <= (ref_carry ? 28'b0 : accum) + diff1;
	stream <= {stream[11:0],diff1};
	stream_strobe <= refcnt[1:0] == 0;
end

// Latch/pipeline one more time to perimeter of this module
// to make routing easier
always @(posedge usbclk) begin
	frequency <= result;
	diff_stream <= stream;
	diff_stream_strobe <= stream_strobe;
end

endmodule
