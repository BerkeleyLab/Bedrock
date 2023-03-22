`timescale 1ns / 1ns
// DSP component for GPS pps discipline of VCTCXO
// input phase is assumed static for several cycles after istrobe
module pps_loop_filter(
	input clk,
	input istrobe,
	// phase is intended static for several cycles on and following istrobe
	input signed [11:0] phase,
	input dac_preset_stb,
	input [15:0] dac_preset_val,
	// what about gain control?  For now it's hard coded.
	output overflow,  // intended to stop feedback mode
	output dac_stb,
	output [15:0] dac_val
);

// input port dac_preset_val and output port dac_val are hardware-centric
// (for the AD5662), and therefore unsigned.
wire signed [15:0] dac_preset_sval = dac_preset_val ^ (1<<15);

// Kp = -8, Ki = -1, on the low side, see transient.py
reg istrobe1=0, istrobe2=0;
wire signed [15:0] prop_term = phase <<< 3;
wire signed [15:0] intg_term = phase <<< 0;
reg signed [15:0] istate=0;
reg signed [16:0] new_istate=0, raw_sum=0;
wire new_istate_ovf = new_istate[16] != new_istate[15];
wire raw_sum_ovf = raw_sum[16] != raw_sum[15];
reg dac_stb_r=0, overflow_r=0;
always @(posedge clk) begin
	istrobe1 <= istrobe;
	istrobe2 <= istrobe1;
	if (dac_preset_stb) istate <= dac_preset_sval;
	if (istrobe) new_istate <= istate - intg_term;
	if (istrobe) raw_sum <= istate - prop_term;
	if (istrobe1) overflow_r <= new_istate_ovf | raw_sum_ovf;
	if (istrobe2 & ~overflow) istate <= new_istate;
	dac_stb_r <= istrobe2 & ~overflow;
end
assign dac_stb = dac_stb_r;
assign dac_val = raw_sum ^ (1<<15);
assign overflow = overflow_r;

endmodule
