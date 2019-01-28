`timescale 1ns / 1ns

// Pin compatible with second_if_out,
// but his one is tuned for close-in SSB output hardware such as built
// at Fermilab to attach to their MFC. Thus two DAC outputs are provided.
// Directly uses the provided LO (cosa,sina).
module ssb_out(
	input clk,
	input [1:0] div_state,
	input signed [17:0] drive,
	input enable,
	//input handedness,
	// local oscillator
	input signed [17:0] cosa,
	input signed [17:0] sina,
	// DDR on both DACs
	output signed [15:0] dac1_out0,
	output signed [15:0] dac1_out1,
	output signed [15:0] dac2_out0,
	output signed [15:0] dac2_out1
);

wire iq = div_state[0];

// Bring input I and Q to full data rate
wire signed [16:0] drive_i, drive_q;
fiq_interp interp(.clk(clk),
	.a_data(drive[17:2]), .a_gate(1'b1), .a_trig(iq),
	.i_data(drive_i), .q_data(drive_q));

wire signed [15:0] out1, out2;

flevel_set level1(.clk(clk),
	.cosd(cosa), .sind(sina),
	.i_data(drive_i), .i_gate(1'b1), .i_trig(1'b1),
	.q_data(drive_q), .q_gate(1'b1), .q_trig(1'b1),
	.o_data(out1));

flevel_set level2(.clk(clk),
	.cosd(cosa), .sind(sina),
	.i_data(drive_q), .i_gate(1'b1), .i_trig(1'b1),
	.q_data(~drive_i), .q_gate(1'b1), .q_trig(1'b1),
	.o_data(out2));

wire signed [15:0] outk1 = enable ? out1 : 0;
wire signed [15:0] outk2 = enable ? out2 : 0;

// afterburner requires freq.vh with a valid value of AFTERBURNER_COEFF,
// even though its value is ovverriden by the coeff parameter.
// coeff configuration for FNAL test:
//   1313 MHz LO used as timebase, divide by 16 to get 82.0625 MHz ADC clock
//   IF is 13 MHz, 16/101 = 0.1584 of ADC clock
parameter ab_coeff = 18646;  // floor(32768*0.5*sec(2*pi*16/101/2)+0.5)

wire [15:0] dac1_ob0, dac1_ob1;  // offset binary outputs from afterburner
afterburner #(.coeff(ab_coeff)) afterburner1(.clk(clk), .data({outk1,1'b0}),
	.data_out0(dac1_ob0), .data_out1(dac1_ob1));
assign dac1_out0 = {~dac1_ob0[15], dac1_ob0[14:0]};
assign dac1_out1 = {~dac1_ob1[15], dac1_ob1[14:0]};

wire [15:0] dac2_ob0, dac2_ob1;  // offset binary outputs from afterburner
afterburner #(.coeff(ab_coeff)) afterburner2(.clk(clk), .data({outk2,1'b0}),
	.data_out0(dac2_ob0), .data_out1(dac2_ob1));
assign dac2_out0 = {~dac2_ob0[15], dac2_ob0[14:0]};
assign dac2_out1 = {~dac2_ob1[15], dac2_ob1[14:0]};

// afterburner returns offset-binary DAC words, but this module uses signed
// (twos-complement) for its output.  Thus the stupid conversions above.
endmodule
