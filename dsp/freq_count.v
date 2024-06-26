// Synthesizes to 86 slices at 312 MHz in XC3Sxxx-4 using XST-8.2i
//  (well, that's just the unknown frequency input; max sysclk is 132 MHz)

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
	output [freq_width-1:0] frequency,
	output freq_strobe,
	output [15:0] diff_stream,
	output diff_stream_strobe,
	// glitch_catcher can be routed to a physical pin to trigger
	// a 'scope; see glitch_thresh parameter above
	output glitch_catcher
);

freq_gcount #(
	.glitch_thresh(glitch_thresh),
	.refcnt_width(refcnt_width),
	.freq_width(freq_width),
	.initv(initv)
) work (
	.sysclk(sysclk), .f_in(f_in),
	.g_in(1'b1),  // this is the whole point!
	.frequency(frequency), .freq_strobe(freq_strobe),
	.diff_stream(diff_stream), .diff_stream_strobe(diff_stream_strobe),
	.glitch_catcher(glitch_catcher)
);

endmodule
