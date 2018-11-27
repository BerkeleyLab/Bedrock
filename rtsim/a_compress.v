`timescale 1ns / 1ns

// Relatively simple model of an amplifier with gain compression
// Larry Doolittle, LBNL, June 2014
// No AM/PM, very little adjustability
// See a_comp.m
// Input is in IQ pairs, I when iq is high, Q when iq is low.
// Output is delayed 11 clock cycles, and thus comes out "incorrectly"
// aligned with iq.
module a_compress(
	input clk,
	input iq,
	input signed [17:0] d_in,
	output signed [17:0] d_out,
	// Adjust saturation characteristics
	input [15:0] sat_ctl   // external
);

// Pipeline match
// "Free" spot for multiplier for overall gain setting (no added latency)
wire signed [17:0] m1;
reg_delay #(.dw(18), .len(9))
	match(.clk(clk), .reset(1'b0), .gate(1'b1), .din(d_in), .dout(m1));

// Mangnitude-square of the input
wire signed [18:0] mag2;
mag_square square(.clk(clk), .iq(iq), .d_in(d_in), .mag2_out(mag2));
// mag2 is guaranteed positive!

// Now find an approximate 1/(1+mag2)
// See a_comp.m
reg signed [18:0] gain=0;
reg signed [35:0] quad1=0;
wire signed [17:0] quad1s=quad1[34:17];
reg signed [17:0] quad2=0, quad3=0;
reg [18:0] mag3=0, mag4=0, mag5=0;
wire quad_sel = mag4[17];
reg signed [19:0] line1=0;
always @(posedge clk) begin
	mag3 <= mag2;  mag4 <= mag3; mag5 <= mag4; // just to match quad pipeline
	line1 <= (mag3>>>1) - 32768;
	quad1 <= $signed(mag2[18:1])*$signed(mag2[18:1]);
	quad2 <= quad1s;
	quad3 <= quad_sel ? line1 : quad2;
	gain <= 163840 + sat_ctl - mag5 + quad3;
end

// Apply the gain function to the (delayed) input
reg signed [35:0] prod1=0;
wire signed [17:0] prod1s=prod1[33:16];
reg signed [17:0] prod2=0;
always @(posedge clk) begin
	prod1 <= m1*$signed({1'b0,gain[17:1]});
	prod2 <= prod1s;
end

assign d_out=prod2;

endmodule
