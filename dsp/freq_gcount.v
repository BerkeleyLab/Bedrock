// Copied from the old freq_count, but with new g_in (gate) input added
// Read the new name as frequency (gated) count.
//
// This version delegates reference counter function to the caller,
// to allow synchronization and resource-sharing across multiple
// freq_gcount instances.  Note that if you want a _lot_ of frequency
// counter instances, maybe you should look into multi_counter.v.
//
// It no longer includes the obscure glitch diagnostics.  Those are
// still available in freq_count, just in case anyone wants them.

`timescale 1ns / 1ns

module freq_gcount #(
	parameter gw=4,  // Gray code counter width
	parameter freq_width=28,
	parameter initv=0  // output value for frequency at start-up
) (
	// input clocks
	input sysclk,  // timespec 8.0 ns
	input f_in,  // unknown input

	// control input in f_in domain
	input g_in,  // gate (wire to 1 to get a simple frequency counter)

	// control input in sysclk domain
	input ref_strobe,  // typically one pulse every 2^24 sysclk cycles

	// outputs in sysclk domain
	output [freq_width-1:0] frequency,
	output freq_strobe,
	output [gw-1:0] xcount  // cycle-by-cycle gated count of f_in
);

// four-bit (nominal) Gray code counter on the input signal
// https://en.wikipedia.org/wiki/Gray_code
reg [gw-1:0] gray1=0;

// The following three expressions compute the next Gray code based on
// the current Gray code.  Vivado 2016.1, at least, is capable of reducing
// them to the desired four LUTs when gw==4.
// verilator lint_save
// verilator lint_off UNOPTFLAT
wire [gw-1:0] bin1 = gray1 ^ {1'b0, bin1[gw-1:1]};  // Gray to binary
// verilator lint_restore
wire [gw-1:0] bin2 = bin1 + 1;  // add one
wire [gw-1:0] gray_next = bin2 ^ {1'b0, bin2[gw-1:1]};  // binary to Gray
always @(posedge f_in) if (g_in) gray1 <= gray_next;

// transfer that Gray code to the measurement clock domain
(* ASYNC_REG = "TRUE" *) reg [gw-1:0] gray2=0, gray3=0;
always @(posedge sysclk) begin
	gray2 <= gray1;
	gray3 <= gray2;
end

// verilator lint_save
// verilator lint_off UNOPTFLAT
wire [gw-1:0] bin3 = gray3 ^ {1'b0, bin3[gw-1:1]};  // Gray to binary
// verilator lint_restore

reg [gw-1:0] bin4=0, bin5=0, diff1=0;
always @(posedge sysclk) begin
	bin4 <= bin3;
	bin5 <= bin4;
	diff1 <= bin4-bin5;
end

// Accumulate diff1 to get a traditional frequency counter
reg [freq_width-1:0] accum=0, result=initv;
reg freq_strobe_r=0;
always @(posedge sysclk) begin
	accum <= (ref_strobe ? {freq_width{1'b0}} : accum) + diff1;
	if (ref_strobe) result <= accum;
	freq_strobe_r <= ref_strobe;  // high when new data is valid
end

assign frequency = result;  // Don't over-register
assign freq_strobe = freq_strobe_r;
assign xcount = diff1;

endmodule
