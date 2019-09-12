`timescale 1ns / 1ns

// Applies a pair of complex couplings to an interleaved IQ data stream
// Larry Doolittle, LBNL, May 2014
// Uses two multipliers
// Fabric use is dominated by an 18-bit fully unrolled CORDIC processor
// Intended to be clocked at twice the ADC clock rate, should work
// at full speed in any of V5, V6, A7, K7.  Should come close on S6.

module pair_couple(
	input clk,
	// Input signal on waveguide given in IQ form
	input iq,  // high for I, low for Q
	input signed [17:0] drive,
	input [18:0] lo_phase,  // should change every other cycle, see below
	// lo_phase must also include the mech_phase component, if applicable
	// Pair of output signals, interleaved, at 20 MHz IF
	input signed [17:0] out_coupling,  // external
	output [0:0] out_coupling_addr,    // external
	input signed [18:0] out_phase_offset,  // external
	output [0:0] out_phase_offset_addr,    // external
	output signed [18:0] pair
);

assign out_coupling_addr = iq;
assign out_phase_offset_addr = ~iq;
// Did you see that magic ~ in the previous line?  That's the cheaters'
// way to match the one-cycle delay in the lo_phase addition below.

// Convert out-coupling magnitude and total phase to coupling's X and Y
reg [18:0] out_phase=0;
always @(posedge clk) out_phase <= lo_phase+out_phase_offset;
wire signed [17:0] xout, yout;
cordicg_b22 #(.nstg(20), .width(18)) ocordic(.clk(clk), .opin(2'b0),
	.xin(out_coupling), .yin(18'b0), .phasein(out_phase),
	.xout(xout), .yout(yout));

// Line up IQ interleaved drive to a steady complex number
reg signed [17:0] drive1=0, d_real=0, d_imag=0;
always @(posedge clk) begin
	drive1 <= drive;
	if (iq) begin
		d_real <= drive;
		d_imag <= drive1;
	end
end

// Multiply two complex numbers to get real component, contribution to ADC.
// If lo_phase is changing, and you set the two couplings the same, it's
// easy to verify in simulation that d_real, d_imag, xout, and yout are
// stable for the same pair of clock cycles.
reg signed [35:0] prodx=0, prody=0;
wire signed [17:0] prodxs = prodx[34:17];
wire signed [17:0] prodys = prody[34:17];
reg signed [17:0] prodx2=0, prody2=0;
reg signed [18:0] out_sum=0;
always @(posedge clk) begin
	prodx <= xout*d_real;  prodx2 <= prodxs;
	prody <= yout*d_imag;  prody2 <= prodys;
	out_sum <= prodx2 - prody2;
end
// Carry an extra msb forward here, don't saturate.
// At least sometimes this just goes to another sum.
assign pair = out_sum;

endmodule
