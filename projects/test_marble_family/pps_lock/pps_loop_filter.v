`timescale 1ns / 1ns
// DSP component for GPS pps discipline of VCTCXO
// input phase is assumed static for several cycles after istrobe
module pps_loop_filter(
	input clk,
	input istrobe,
	input arm,  // used to reset FIR
	// phase is intended static for several cycles on and following istrobe
	input signed [12:0] phase,
	input fir_enable,  // enable [0.5 0.5] FIR
	input dac_preset_stb,
	input [15:0] dac_preset_val,
	// what about gain control?  For now it's hard coded.
	output overflow,  // intended to stop feedback mode
	output dac_stb,
	output [15:0] dac_val  // offset-binary
);

// input port dac_preset_val and output port dac_val are hardware-centric
// (for the AD5662), and therefore unsigned.
wire signed [15:0] dac_preset_sval = dac_preset_val ^ (1<<15);

// Optional FIR
reg signed [12:0] old_phase=0;
reg signed [13:0] phase_filt=0;
reg istrobe1=0;
always @(posedge clk) begin
	istrobe1 <= istrobe;
	if (arm) old_phase <= 0;  // FIR gets a soft and reproducible start
	if (istrobe) begin
		old_phase <= phase;
		phase_filt <= phase + (fir_enable ? old_phase : phase);
	end
end
// With IDDR and fir_enable, phase_filt might really be 14 bits.
// Otherwise there will be one or two dud lsb.

// Kp = -8, Ki = -1, on the low side, see transient.py
reg istrobe2=0, istrobe3=0;
wire signed [17:0] prop_term = phase_filt <<< 3;
wire signed [17:0] intg_term = phase_filt <<< 0;
reg signed [17:0] istate=0;
reg signed [18:0] new_istate=0, raw_sum=0;
wire new_istate_ovf = new_istate[18] != new_istate[17];
wire raw_sum_ovf = raw_sum[18] != raw_sum[17];
reg dac_stb_r=0, overflow_r=0;
always @(posedge clk) begin
	istrobe2 <= istrobe1;
	istrobe3 <= istrobe2;
	if (dac_preset_stb) istate <= dac_preset_sval <<< 2;
	if (istrobe1) new_istate <= istate - intg_term;
	if (istrobe1) raw_sum <= istate - prop_term;
	if (istrobe2) overflow_r <= new_istate_ovf | raw_sum_ovf;
	if (istrobe3 & ~overflow) istate <= new_istate;
	dac_stb_r <= istrobe3 & ~overflow;
end
assign dac_stb = dac_stb_r;
assign dac_val = raw_sum[17:2] ^ (1<<15);
assign overflow = overflow_r;

endmodule
