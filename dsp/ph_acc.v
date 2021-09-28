`timescale 1ns / 1ns
module ph_acc#( // good idea to not touch the defaults (for backwards compatibility)
   parameter MOD_WI = 12,
   parameter PHH_WI = 20,
   parameter PHL_WI = 12,
   parameter OUT_WI = 19
) (
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input reset,  // Active high, synchronous with clk
	input en,   // Enable
	output [OUT_WI-1:0] phase_acc,  // Output phase word
	input [PHH_WI-1:0] phase_step_h,  // High order (coarse, binary) phase step
	input [PHL_WI-1:0] phase_step_l,  // Low order (fine, possibly non-binary) phase step
	input [MOD_WI-1:0] modulo  // Encoding of non-binary modulus; 0 means binary
);

reg carry=0, reset1=0;
reg [PHH_WI-1:0] phase_h=0, phase_step_hp=0;
reg [PHL_WI-1:0] phase_l=0;
always @(posedge clk) if (en) begin
	{carry, phase_l} <= reset ? 0 : ((carry ? modulo : 0) + phase_l + phase_step_l);
	phase_step_hp <= phase_step_h;
	reset1 <= reset;
	phase_h <= reset1 ? 0 : (phase_h + phase_step_hp + carry);
end
assign phase_acc=phase_h[PHH_WI-1:1];

endmodule
