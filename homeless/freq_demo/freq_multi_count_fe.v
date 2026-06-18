// Front-end to multiplexed-input frequency counter
// FPGA-friendly, since there's no actual multiplexed clock:
//  multiplexing happens in the data path, requiring a small amount
//  of logic in each "unknown" clock domain

// See freq_multi_count.v for a longer description of a complete use case.

module freq_multi_count_fe #(
	parameter NF=8,  // number of frequency counters
	parameter gw=4,  // Gray counter width
	parameter uw=28,  // unknown counter width

// Sensible choices for gw are 3 (supports f_unk/f_ref < 6.0) or
// 4 (supports f_unk/f_ref < 14.0).

// It's recommended to not override parameter NA_.  It is not
// set up as a localparam because that triggers toolchain problems.
	parameter NA_=$clog2(NF)   // don't change this!
) (
	// Input clocks
	input [NF-1:0] unk_clk,
	input refclk,
	// All the following inputs and outputs are in the refclk domain
	input [NA_-1:0] clksel,
	input reset,
	output [uw-1:0] frequency
);

// One Gray code counter for each input clock
wire [gw-1:0] gray1[0:NF-1];
genvar ix;
generate for (ix=0; ix<NF; ix=ix+1) begin : gray
	simplest_gray #(.gw(gw))
	// gray3_count
	gc(.clk(unk_clk[ix]), .gray(gray1[ix]));
end endgenerate

// Transfer those Gray codes to the measurement clock domain.
// Note the dependence on clksel here.
(* ASYNC_REG = "TRUE" *) reg [gw-1:0] gray2[0:NF-1], gray3[0:NF-1];
reg [gw-1:0] gray4=0;
integer jx;
initial for (jx=0; jx<NF; jx=jx+1) begin gray2[jx] = 0; gray3[jx] = 0; end
always @(posedge refclk) begin
	for (jx=0; jx<NF; jx=jx+1) begin
		gray2[jx] <= gray1[jx];  // cross domains here
		gray3[jx] <= gray2[jx];  // satisfy metastability rules
	end
	gray4 <= gray3[clksel];  // multiplexing step
end

// Figure out how many unk_clk edges happened in the last refclk period,
// and then accumulate them.  Relegate reference counter and other
// control logic to the module that instantiates us; all we need to
// know is when to zero this accumulator.
// verilator lint_save
// verilator lint_off UNOPTFLAT
wire [gw-1:0] bin4 = gray4 ^ {1'b0, bin4[gw-1:1]}; // convert Gray to binary
// verilator lint_restore
reg [gw-1:0] bin5=0, diff5=0;
reg [uw-1:0] accum=0;
always @(posedge refclk) begin
	bin5 <= bin4;
	diff5 <= bin4 - bin5;
	accum <= reset ? 0 : accum + diff5;
end
assign frequency = accum;

endmodule
