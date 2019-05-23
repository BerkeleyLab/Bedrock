// Synthesizes to 86 slices at 312 MHz in XC3Sxxx-4 using XST-8.2i
//  (well, that's just the unknwon frequency input; max sysclk is 132 MHz)

`timescale 1ns / 1ns

module freq_count #(
	// Default configuration useful for input frequencies < 96 MHz
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

// four-bit Gray code counter on the input signal
// http://en.wikipedia.org/wiki/Gray_code
localparam gw=4;
reg [gw-1:0] gray1=0;

// The following three expressions compute the next Gray code based on
// the current Gray code.  Vivado 2016.1, at least, is capable of reducing
// them to the desired four LUTs when gw==4.
// verilator lint_off UNOPTFLAT
wire [gw-1:0] bin1 = gray1 ^ {1'b0, bin1[gw-1:1]};  // Gray to binary
// verilator lint_on UNOPTFLAT
wire [gw-1:0] bin2 = bin1 + 1;  // add one
wire [gw-1:0] gray_next = bin2 ^ {1'b0, bin2[gw-1:1]};  // binary to Gray
always @(posedge f_in) gray1 <= gray_next;

// transfer that Gray code to the measurement clock domain
reg [gw-1:0] gray2=0, gray3=0;
always @(posedge sysclk) begin
	gray2 <= gray1;
	gray3 <= gray2;
end

// verilator lint_off UNOPTFLAT
wire [gw-1:0] bin3 = gray3 ^ {1'b0, bin3[gw-1:1]}; // convert Gray to binary
// verilator lint_on UNOPTFLAT

reg [gw-1:0] bin4=0, bin5=0, diff1=0;
always @(posedge sysclk) begin
	bin4 <= bin3;
	bin5 <= bin4;
	diff1 <= bin4-bin5;
	if (diff1 > glitch_thresh) glitch_catcher <= ~glitch_catcher;
end

// It might also be possible to histogram diff1,
// but for now just accumulate it to get a traditional frequency counter.
// Also make it available to stream to host at 24 MByte/sec, might be
// especially interesting when reprogramming a clock divider like
// the AD9512 on a LLRF4 board.
// In that case a 48 MHz sysclk / 2^24 = 2.861 Hz update
reg [freq_width-1:0] accum=0, result=initv;
reg [refcnt_width-1:0] refcnt=0;
reg ref_carry=0;
reg [15:0] stream=0;
reg stream_strobe=0;
always @(posedge sysclk) begin
	{ref_carry, refcnt} <= refcnt + 1;
	if (ref_carry) result <= accum;
	accum <= (ref_carry ? 28'b0 : accum) + diff1;
	stream <= {stream[11:0],diff1};
	stream_strobe <= refcnt[1:0] == 0;
end

// Latch/pipeline one more time to perimeter of this module
// to make routing easier
reg freq_strobe_r=0;
always @(posedge sysclk) begin
	frequency <= result;
	freq_strobe_r <= ref_carry;
	diff_stream <= stream;
	diff_stream_strobe <= stream_strobe;
end
assign freq_strobe = freq_strobe_r;

endmodule
