// I2C pin driver/state machine
// Handles timing of one-bit transaction

// Action based on a 2-bit command, encoding
// 0: Tx0  1: Tx1  2: L  3: H
// where SCL is stopped (high) for L and H symbols.

// No support for clock stretching or multi-mastering.

// Can run at pretty much any clk frequency, as long as
// the tick input comes at a regular frequency that's
// 5.6 MHz or slower (for 400 kHz bit rate).
// Also demand at least one clk period between "tick" cycles.
module i2c_bit(
	input clk,
	input tick,
	output advance,
	input [1:0] command,
	output scl_o,
	output sda_o, // drive
	input sda_v,  // pin
	output sda_h   // sampled output for recording
);

// 14 phases within one bit
// 9/14 of 2.5 us is 1.6 us:  SCL low  time, 0.3 us larger than min. spec.
// 5/14 of 2.5 us is 0.9 us:  SCL high time, 0.3 us larger than min. spec.
// SDA transition at 3/14 of 2.5 us = 0.54 us after falling edge of SCL.
reg [3:0] cnt=0;  // count to 14
reg last_tick=0;
always @(posedge clk) begin
	last_tick <= cnt==13;
	if (tick) cnt <= last_tick ? 0 : cnt+1;
end

// Logic to ask for and register commands
assign advance = tick & last_tick;
reg [1:0] cmd=3;
always @(posedge clk) if (advance) cmd <= command;

// Waveform synthesis
reg scl_o_r=1, sda_o_r=1, old_bit=1, sda_h_r=1;
wire new_bit = cmd[0];
always @(posedge clk) begin
	// 3/14 of 2.5 us
	sda_o_r <= (cnt<3) ? old_bit : new_bit;
	if (advance) old_bit <= new_bit;
	// scl is high for 50 clock cycles or 5 of 14 cnt
	// scl is low for 90 clock cycles or 9 of 14 cnt
	scl_o_r <= cmd[1] ? 1 : cnt>=9;
	if (cnt == 8) sda_h_r <= sda_v;
end

assign scl_o = scl_o_r;
assign sda_o = sda_o_r;
assign sda_h = sda_h_r;

endmodule
