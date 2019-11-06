`timescale 1ns / 1ns

// Pin compatible with ssb_out,
// but this is tuned for the LCLS-II configuration where it
// needs to generate 145 MHz, even though the input lo (cosa,sina)
// is at 20 MHz (7/33 of clk rate).  Only DAC1 is provided.
module second_if_out(
	input clk,
	input [1:0] div_state,
	input signed [17:0] drive,
	input enable,
	//input handedness,
	// local oscillator
	input signed [17:0] cosa,
	input signed [17:0] sina,
	// DDR to a single DAC
	output signed [15:0] dac1_out0,
	output signed [15:0] dac1_out1,
	// Unused
	output signed [15:0] dac2_out0,
	output signed [15:0] dac2_out1
);

wire iq = div_state[0];

// Bring input I and Q to full data rate
wire signed [16:0] drive_i, drive_q;
fiq_interp interp(.clk(clk),
	.a_data(drive[17:2]), .a_gate(1'b1), .a_trig(iq),
	.i_data(drive_i), .q_data(drive_q));

// Convert the 7/33 LO to 61/132 by (complex) multiplying by a 1/4 LO.
// This is "cheap" and adds the minimum extra divider state.
// Only has value because we keep the LO in complex form.
wire signed [17:0] cosi = ~cosa;
wire signed [17:0] sini = ~sina;
reg signed [17:0] cosb=0, sinb=0;
always @(posedge clk) case(div_state)
	2'b00: begin cosb <= cosa;  sinb <= sina;  end
	2'b01: begin cosb <= sini;  sinb <= cosa;  end
	2'b10: begin cosb <= cosi;  sinb <= sini;  end
	2'b11: begin cosb <= sina;  sinb <= cosi;  end
endcase

// Interpolate between points, given that we know the phase step
// is 61/264 (image 203/264) in the double-data-rate DAC clock domain;
// that's the desired analog output:  1320/14*203/132 = 145 MHz.
// Use 1/16 as an approximation for 5/528 * 2*pi.

reg signed [17:0] cosb1=0, sinb1=0, cosb2=0, sinb2=0;
always @(posedge clk) begin
	// multiply by 1+i/16
	cosb1 <= cosb - (sinb>>>4);
	sinb1 <= sinb + (cosb>>>4);
	// multiply by i+1/16
	cosb2 <= ~sinb + (cosb>>>4);
	sinb2 <= cosb + (sinb>>>4);
end

wire signed [15:0] out1, out2;

flevel_set level1(.clk(clk),
	.cosd(cosb1), .sind(sinb1),
	.i_data(drive_i), .i_gate(1'b1), .i_trig(1'b1),
	.q_data(drive_q), .q_gate(1'b1), .q_trig(1'b1),
	.o_data(out1));

flevel_set level2(.clk(clk),
	.cosd(cosb2), .sind(sinb2),
	.i_data(drive_i), .i_gate(1'b1), .i_trig(1'b1),
	.q_data(drive_q), .q_gate(1'b1), .q_trig(1'b1),
	.o_data(out2));

wire signed [15:0] outk1 = enable ? out1 : 0;
wire signed [15:0] outk2 = enable ? out2 : 0;

assign dac1_out0 = outk1;
assign dac1_out1 = outk2;
assign dac2_out0 = 0;
assign dac2_out1 = 0;

endmodule
