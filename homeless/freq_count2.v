`timescale 1ns / 1ns

module freq_count2(
	// input clocks
	input f_in,  // timespec 8.0 ns
	input clk,

	// output
	output reg [31:0] frequency,
	output reg strobe
);

// 125 MHz clk / 2^27 = 0.931 Hz update
// reduce this for testing
parameter REFCNT_WIDTH=27;

initial begin
	frequency=0;
	strobe=0;
end

// four-bit Gray code counter on the input signal
// http://en.wikipedia.org/wiki/Gray_code
reg [3:0] bin1=0, gray1=0;
always @(posedge f_in) begin
	bin1 <= bin1 + 1;
	gray1 <= bin1 ^ {1'b0, bin1[3:1]};
end

// transfer that Gray code to the measurement clock domain
reg [3:0] gray2=0, gray3=0;
always @(posedge clk) begin
	gray2 <= gray1;
	gray3 <= gray2;
end

wire [3:0] bin3 = gray3 ^ {1'b0, bin3[3:1]}; // convert Gray to binary

reg [3:0] bin4=0, bin5=0, diff1=0;
always @(posedge clk) begin
	bin4 <= bin3;
	bin5 <= bin4;
	diff1 <= bin4-bin5;
end

// I'd like to histogram diff1, but for now just accumulate it.
// Also make it available to stream to host at 24 MByte/sec, might be
// especially interesting when reprogramming the AD9512.
reg [31:0] accum=0, result=0;
reg [REFCNT_WIDTH-1:0] refcnt=0;
reg ref_carry=0;
always @(posedge clk) begin
	{ref_carry, refcnt} <= refcnt + 1;
	accum <= (ref_carry ? 0 : accum) + diff1;
	if (ref_carry) result <= accum;
end

// Latch/pipeline one more time to perimeter of this module
// to make routing easier
always @(posedge clk) begin
	frequency <= result;
	strobe <= ref_carry;
end

endmodule
