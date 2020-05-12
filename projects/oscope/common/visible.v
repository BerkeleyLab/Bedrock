// Create a helpful test pattern to identify output pins

// Attach each bit from the "pattern" output port to an output pin;
// you can then visually identify pins by looking at the trace with
// an oscilloscope.
module visible(
	input clk,
	output [15:0] pattern
);

// Get down to a reasonable rate for 'scope probes
// div==6 yields 1.28 us granularity when running from 50 MHz local bus clock.
parameter div = 6;
reg [div-1:0] pre_cnt=0;
reg tick=0;
always @(posedge clk) begin
	pre_cnt <= pre_cnt+1;
	tick <= &pre_cnt;
end

// Count, and start decoding it
reg [7:0] count=0;
reg in_block=0, start_bit=0, stop_bit=0;
always @(posedge clk) if (tick) begin
	count <= count+1;
	in_block <= count[7:5]==0;
	start_bit <= count[2:0]==0;
	stop_bit <= count[2:0]==7;
end

// Key stanza to create all the serial streams
reg [15:0] pat_bits=0;
genvar ix;
generate for (ix=0; ix<16; ix=ix+1) begin
	wire [3:0] ixx = ix;
	always @(posedge clk) if (tick) pat_bits[ix] <= ixx[count[4:3]];
end endgenerate

// Put it all together
reg [15:0] result=0;
always @(posedge clk) if (tick) begin
	result <= (~in_block | stop_bit) ? 16'h0000 : start_bit ? 16'hffff : pat_bits;
end
assign pattern=result;

endmodule
