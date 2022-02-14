`timescale 1ns / 1ns

// Phase accumulator, to act as basis for DDS (direct digital synthesizer).
// Tuned to allow 32-bit control, divided 20-bit high and 12-bit low,
// which gets merged to 32-bit binary when modulo is zero.
// But also supports non-binary frequencies: see the modulo input port.
module ph_acc(
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input reset,  // Active high, synchronous with clk
	input en,   // Enable
	output [18:0] phase_acc,  // Output phase word
	input [19:0] phase_step_h,  // High order (coarse, binary) phase step
	input [11:0] phase_step_l,  // Low order (fine, possibly non-binary) phase step
	input [11:0] modulo  // Encoding of non-binary modulus; 0 means binary
);

reg carry=0, reset1=0;
reg [19:0] phase_h=0, phase_step_hp=0;
reg [11:0] phase_l=0;
always @(posedge clk) if (en) begin
	{carry, phase_l} <= reset ? 13'b0 : ((carry ? modulo : 12'b0) + phase_l + phase_step_l);
	phase_step_hp <= phase_step_h;
	reset1 <= reset;
	phase_h <= reset1 ? 20'b0 : (phase_h + phase_step_hp + carry);
end
assign phase_acc=phase_h[19:1];

endmodule
