// Stripped-down logic analyzer to look at I2C bus
// Plan that it's small enough to include on every build.
// That includes sharing its output memory with the rest of
// the I2C subsystem.  Should be useful with 1K x 8 output.
// Needs a corresponding (python) program to convert that
// buffer memory to a .vcd file.  Compare with ctrace.v.

module i2c_analyze(
	input clk,
	input tick,
	// four hardware input pins
	input scl,
	input sda,
	input intp,
	input rst,
	output trig_out,  // edge sensitive
	// command to i2c_bit, ignore at first, but really important
	input bit_adv,
	input [1:0] bit_cmd,
	// bytes pushed to memory
	output [7:0] trace,
	output trace_push,
	// Run control; lower this when memory is full
	input run
);
// It would be nice if bit_adv were synchronized with tick.

localparam dw=2;  // just scl and sda
localparam tw=6;

wire [1:0] data = {scl, sda};
reg [tw-1:0] count = 0;
reg [dw-1:0] data1 = 0, data2 = 0; // pipeline
reg diff = 0;
reg of = 0;  // counter overflow

wire wen = run & (diff | of);
reg tick1=0, wen1=0;
always @(posedge clk) begin
	tick1 <= tick;
	if (tick) begin
		data1 <= data;
		diff <= data1 != data;
	end
	if (tick1) begin
		{of, count} <= wen | ~run ? 1 : count + 1;
		data2 <= data1;
	end
end

assign trace = {count, data2};
assign trace_push = wen & tick1;
assign trig_out = diff;  // re-use logic

endmodule
