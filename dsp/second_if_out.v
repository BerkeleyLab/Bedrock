`timescale 1ns / 1ns

// Pin compatible with ssb_out,
// but this is tuned for the LCLS-II configuration where it
// needs to generate 145 MHz, even though the input lo (cosa,sina)
// is at 20 MHz (7/33 of clk rate).  Only DAC1 is provided.
module second_if_out(
	input clk,
	input [1:0] div_state,
	input signed [17:0] drive,
	input lo_sel, // 0 - 145 MHz; 1 - 60 MHz
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

localparam LO_SEL_145 = 0,
           LO_SEL_60 = 1;

wire iq = div_state[0];

// Bring input I and Q to full data rate
wire signed [16:0] drive_i, drive_q;
fiq_interp interp(.clk(clk),
	.a_data(drive[17:2]), .a_gate(1'b1), .a_trig(iq),
	.i_data(drive_i), .q_data(drive_q));

// ---------------------------------
// 43.6 / 145 MHz LO generation
// ---------------------------------

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

// ---------------------------------
// 60 MHz LO generation
// ---------------------------------

reg [5:0] lut_addr=0;
wire [5:0] lut_addr1;
wire signed [17:0] sin40, cos40, sin40_1, cos40_1;

always @(posedge clk) lut_addr <= (lut_addr == 32) ? 0 : lut_addr + 1;
assign lut_addr1 = (lut_addr == 32) ? 0 : lut_addr + 1;

lo_lut i_lo_lut (
   .clk (clk),
   .sin_addr (lut_addr), .cos_addr (lut_addr),
   .sin_data (sin40), .cos_data (cos40));

lo_lut i_lo_lut1 (
   .clk (clk),
   .sin_addr (lut_addr1), .cos_addr (lut_addr1),
   .sin_data (sin40_1), .cos_data (cos40_1));

wire signed [17:0] cos_mix, sin_mix, cos_mix1, sin_mix1;

cpxmul_fullspeed i_cpxmul (
   .clk (clk),
   .re_a (cos40), .im_a (sin40),
   .re_b (cosa), .im_b (sina),
   .re_out (cos_mix), .im_out (sin_mix)
);

cpxmul_fullspeed i_cpxmul1 (
   .clk (clk),
   .re_a (cos40_1), .im_a (sin40_1),
   .re_b (cosa), .im_b (sina),
   .re_out (cos_mix1), .im_out (sin_mix1)
);


// ---------------------------------
// LO selection and IQ mixing
// ---------------------------------

wire signed [15:0] out1, out2;
reg signed [17:0] cos_lo1, sin_lo1, cos_lo2, sin_lo2;

always @(*) begin
   case (lo_sel)
      LO_SEL_145: begin
         cos_lo1 = cosb1; sin_lo1 = sinb1;
         cos_lo2 = cosb2; sin_lo2 = sinb2;
      end
      default : begin // LO_SEL_60
         cos_lo1 = cos_mix; sin_lo1 = sin_mix;
         cos_lo2 = cos_mix1; sin_lo2 = sin_mix1;
      end
   endcase
end

flevel_set level1(.clk(clk),
	.cosd(cos_lo1), .sind(sin_lo1),
	.i_data(drive_i), .i_gate(1'b1), .i_trig(1'b1),
	.q_data(drive_q), .q_gate(1'b1), .q_trig(1'b1),
	.o_data(out1));

flevel_set level2(.clk(clk),
	.cosd(cos_lo2), .sind(sin_lo2),
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
