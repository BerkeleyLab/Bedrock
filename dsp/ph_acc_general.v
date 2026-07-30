`timescale 1ns / 1ns
// Derived from bedrock/ph_acc.v

module ph_acc_general #(
   parameter integer DWL = 12,
   parameter integer DWH = 20,
   parameter integer DWO = 19
)(
	input clk,
	input reset,  // assert after changing phase steps
	output [DWO-1:0] phase_acc,  // Output phase word
	input [DWH-1:0] phase_step_h,  // High order (coarse, binary) phase step
	input [DWL-1:0] phase_step_l,  // Low order (fine, possibly non-binary) phase step
	input [DWL-1:0] modulo  // Encoding of non-binary modulus; 0 means binary
);

reg carry=0, reset1=0;
reg [DWH-1:0] phase_h=0, phase_step_hp=0;
reg [DWL-1:0] phase_l=0;
always @(posedge clk) begin
	if (reset || reset1) begin
		carry <= 1'b0;
		phase_l <= {DWL{1'b0}};
		phase_h <= {DWH{1'b0}};
		phase_step_hp <= {DWH{1'b0}};
	end else begin
		{carry, phase_l} <= (carry ? modulo : {(DWL+1){1'b0}}) + phase_l + phase_step_l;
		phase_step_hp <= phase_step_h;
		phase_h <= phase_h + phase_step_hp + carry;
	end
	reset1 <= reset;
end
assign phase_acc = phase_h[DWH-1:DWH-DWO];

endmodule
