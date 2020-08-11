`timescale 1ns / 1ns

//Up-conversion using Double-sideband Modulator 
//check out pg. 268 from https://cds.cern.ch/record/1100538/files/p249.pdf
//Digital quadrature modulation followed by analog up-conversion mixer
//rf_out = I*cos(wt) + Q*sin(wt)

module dsb (
	input clk,
	input div_state,     //div_state I-Q signal 
	input signed [17:0] drive, //Based interleaved I-Q
	
	// DDS
	input signed [17:0] cosa, 
	input signed [17:0] sina, 

	//DAC output 
	output signed [15:0] dac_out
);

wire iq = div_state;
wire signed [16:0] drive_i, drive_q;
wire signed [15:0] out;

fiq_interp interp(.clk(clk),
	.a_data(drive[17:2]), .a_gate(1'b1), .a_trig(iq),
	.i_data(drive_i), .q_data(drive_q));

flevel_set level(.clk(clk),
	.cosd(cosa), .sind(sina),
	.i_data(drive_i), .i_gate(1'b1), .i_trig(1'b1),
	.q_data(drive_q), .q_gate(1'b1), .q_trig(1'b1),
	.o_data(out));


assign dac_out = out;

endmodule
