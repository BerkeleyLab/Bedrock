// ramped-edge pulse generator
// Intended as the amplitude modulation of a chirp generator
// Mostly cribbed from fgen.v
module ramps #(
	parameter dw = 16,  // width of amplitude computations
	parameter cw = 32  // counter width
) (
	input clk,
	input gate,
	input reset,
	output gate_o,
	input [cw-1:0] duration,
	input [dw-1:0] amp_slope,
	input [dw-1:0] amp_max,
	output [dw-1:0] amp,
	output a_warning,
	output error
);

reg error_r = 0;
reg gate_r = 0;
always @(posedge clk) gate_r <= gate;
assign gate_o = gate_r;
assign error = error_r;

// Pulse generator
// Off time initiates fall of ramp above
// Pipeline step requires every gate pulse preceded by a non-gate cycle
reg pulse_on = 0;
reg [cw-1:0] counter=0;
reg counter_zero=0;
always @(posedge clk) begin
	counter_zero <= counter==rise_t; // Start off-ramp rise_t cycles before end of chirp length
	if (reset | (gate & pulse_on & ~counter_zero)) counter <= reset ? duration : counter-1;
	if (reset | (gate & counter_zero)) pulse_on <= reset;
	error_r <= gate & gate_r;
end

// Make pulse into analog, with adjustable rise and fall time
reg [dw:0] amp_step = 0;
reg [dw-1:0] amp_r = 0;
wire [dw-1:0] amp_zero = 0;
wire [dw-1:0] amp_flat = (pulse_on & ~reset) ? amp_max : amp_zero;
reg amp_railed = 0;
reg amp_nonzero = 0;
reg a_warning_r = 0;
always @(posedge clk) begin
	// Hope amp_step gets synthesized with ADDSUB primitive
	amp_step <= pulse_on ? amp_r+amp_slope : amp_r-amp_slope;
	amp_railed <= pulse_on ? (amp_step > amp_flat) : amp_step[dw];
	amp_nonzero <= |amp_r;
	if (gate) amp_r <= amp_railed ? amp_flat : amp_step;
	// amplitude needs to be back to zero when next reset hits
        // for robustness to incorrect parameters, force it low
        if (reset) amp_r <= 0;
	a_warning_r <= reset & amp_nonzero;
end
assign amp = amp_r;
assign a_warning = a_warning_r;

// Determine rise time; to be used in off-ramp
reg [cw-1:0] rise_cnt=0, rise_t=0;
always @(posedge clk) begin
	if (reset) begin
		rise_cnt <= 0;
		rise_t <= 0;
	end

	if (pulse_on && gate)
		if (!amp_railed)
			rise_cnt <= rise_cnt + 1;
		else
			rise_t <= rise_cnt+2;
end

endmodule
