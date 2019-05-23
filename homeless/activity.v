`timescale 1ns / 1ns

// Relatively simple LED driver to show presence of events,
// e.g., network packets arriving.
// LED on pulse lasts 2^(cw-1) cycles (0.27 seconds with default
// parameter cw=26 and 125 MHz clock) for a single event.
// With a "steady" stream of events, keeps going with that same
// on time and off time, period 2^(cw) cycles.

module activity(
	input clk,  // timespec 8.0 ns
	input trigger,
	output led
);

parameter cw=26;
reg [cw-1:0] cnt=0;
reg arm=0;
wire start = trigger & ~cnt[cw-1];
always @(posedge clk) begin
	if (arm | (|cnt)) cnt <= cnt-1;
	if (start | ~(|cnt)) arm <= start;
end

assign led = cnt[cw-1];

endmodule
