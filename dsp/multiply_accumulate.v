`timescale 1ns / 1ns

/// TL;DR
/// accumulated += ((constant * signal) >>> downscale) + correction
///
/// Multiply a `constant` K to input `signal` and accumulate the result on `enable`.
///
/// Notice `downscale`, this is meant to downscale the input into the accumulator
/// Useful in times of high "natural" integration gain: like running with a superconducting cavity
///
/// `correction` comes from some externally-supplied feedforward, maybe derived from the previous pulse
module multiply_accumulate #(
	parameter CW = 17,
	parameter KW = 18,  // Constant Width
	parameter SW = 18,  // Signal Width
	parameter OW = 21   // OutputWidth: Desired bitwidth of the accumulator
) (
	input clk,
	input reset,
	input enable,
	input signed [CW-1:0] correction,
	input [3:0] downscale,
	input signed [KW-1:0] constant,
	input signed [SW-1:0] signal,
	output signed [OW-1:0] accumulated
);

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

reg signed [KW+SW-1: 0] integrator_in_large=0;
reg signed [OW-1: 0] integrator_sum=0;

wire signed [OW-1: 0] integrator_in = $signed(integrator_in_large[KW+SW-1: KW+SW-1 - 20]) >>> downscale;
wire signed [OW:0] integrator_sum_pre = (enable? integrator_in + correction : 0) + integrator_sum;

always @ (posedge clk) begin
	if (reset) integrator_sum <= 0;
	else begin
		integrator_in_large <= signal * constant;
		// TODO: Turning off the bit error for now
		integrator_sum <= `SAT(integrator_sum_pre, OW, OW-1);
	end
end

`undef SAT

assign accumulated = integrator_sum;

endmodule
