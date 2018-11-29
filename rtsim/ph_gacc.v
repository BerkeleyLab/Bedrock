`timescale 1ns / 1ns
module ph_gacc(
	input clk,  // timespec 9.0 ns
	input reset,  // active high, synchronous with clk
	input gate,
	output [18:0] phase_acc,
	input [19:0] phase_step_h,
	input [11:0] phase_step_l,
	input [11:0] modulo
);

reg carry=0, reset1=0, gate1=0;
reg [19:0] phase_h=0, phase_step_hp=0;
reg [11:0] phase_l=0;
always @(posedge clk) begin
	if (gate) {carry, phase_l} <= reset ? 13'b0 : ((carry ? modulo : 12'b0) + phase_l + phase_step_l);
	if (gate) phase_step_hp <= phase_step_h;
	reset1 <= reset;
	gate1 <= gate;
	if (gate1) phase_h <= reset1 ? 20'b0 : (phase_h + phase_step_hp + carry);
end
assign phase_acc=phase_h[19:1];

endmodule
