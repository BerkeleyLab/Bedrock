// Downconversion of an IF at 5/12 of clock rate as used by proposed
// SNS PPU hardware.
//
// Output sig_i, sig_q, and sig_dc represent amplitude of input adc signal.
// A full-scale sine wave on the ADC (span -32767 to 32767) will read 32767
// as sqrt(sig_i^2+sig_q^2).  The sig_i and sig_q outputs have one extra msb,
// allowing them to represent clipped input signals.  Conversion in that case
// has unwanted phase sensitivity, and sublinear but monotonic amplitude de-
// pendence, such that the largest possible result is 42400, a.k.a. +2.2 dBFS.
// Output sig_cl is updated along with the other sig_, reports clip status.
//
// A simple decimating downconverter that does not reject DC will have a
// processing (power) gain of N/2, when N=6 that's 4.771 dB.
// The coefficients used here provide "only" 4.636 dB of processing gain,
// arguably an 0.135 dB Noise Figure contributed by the DC-reject feature.
// For an AD9653 run in 2.0 V p-p input mode, 76.5 + 4.8 = 81.3 dB SNR
// for each of I and Q, contrasted with 74.0 dB for the AD6644 used in
// the original production SNS FCM with a processing gain of 0 dB.
//
// The ADC input can be interpreted as Q1.15, outputs sig_i, sig_q as Q2.15,
// using ARM Q notation that includes the sign bit in m.
// See https://en.wikipedia.org/wiki/Q_(number_format).
//
// The update rate is an IQ pair every 6 cycles, 20 MS/s with 120 MHz clock,
// equivalent to the 2003-era SNS LLRF.  Updates are marked with a high
// level on the stb output.
// Group delay is 8 clock cycles, approximately 67 ns, including the
// intrinsic FIR filter delay, two stages of logic/pipelining, and the
// output sample-and-hold.
//
// sig_rms is only updated at one-third the rate of the other outputs,
// and also suffers from additional latency.
// One sig_rms quantum is 0.236 ADC bits (1/sqrt(18)).
//
// If you choose not to wire up sig_dc and sig_rms, only two multipliers
// are needed.  That count rises to six when all outputs are used.
// Multipliers are limited to signed 18x18 (or smaller), efficiently
// implemented by all major FPGA families.
// Synthesis test with XST 14.7 targeting A7:
//   full-featured: 313 Slice LUT, 6 DSP48E1
//   I/Q/clip output only: 56 Slice LUT, 2 DSP48E1
module down_5_12(
	input clk,
	input signed [15:0] adc,
	input [3:0] phase,
	output stb,
	output sig_cl,
	output signed [16:0] sig_i,
	output signed [16:0] sig_q,
	output signed [15:0] sig_dc,
	output [15:0] sig_rms
);

reg signed [17:0] ref_i, ref_q, ref_dc;
// directly cut-and-pasted output of down_meta.py
always @(posedge clk) case (phase)
	 0: begin  ref_i <=  22616;  ref_q <=  73716;  ref_dc <=  30971;  end
	 1: begin  ref_i <= -61788;  ref_q <= -81732;  ref_dc <=  57793;  end
	 2: begin  ref_i <=  84404;  ref_q <=   8016;  ref_dc <=  42308;  end
	 3: begin  ref_i <= -84404;  ref_q <=   8016;  ref_dc <=  42308;  end
	 4: begin  ref_i <=  61788;  ref_q <= -81732;  ref_dc <=  57793;  end
	 5: begin  ref_i <= -22616;  ref_q <=  73716;  ref_dc <=  30971;  end
	 6: begin  ref_i <= -22616;  ref_q <= -73716;  ref_dc <=  30971;  end
	 7: begin  ref_i <=  61788;  ref_q <=  81732;  ref_dc <=  57793;  end
	 8: begin  ref_i <= -84404;  ref_q <=  -8016;  ref_dc <=  42308;  end
	 9: begin  ref_i <=  84404;  ref_q <=  -8016;  ref_dc <=  42308;  end
	10: begin  ref_i <= -61788;  ref_q <=  81732;  ref_dc <=  57793;  end
	11: begin  ref_i <=  22616;  ref_q <= -73716;  ref_dc <=  30971;  end
	default: begin  ref_i <= 18'bx; ref_q <= 18'bx; ref_dc <= 18'bx; end
endcase

// OK to drop high bit, because our "LO" table is never full-scale negative
reg signed [32:0] mult_i, mult_q, mult_d;
reg adc_clip1=0;
always @(posedge clk) begin
	mult_i <= ref_i * adc;
	mult_q <= ref_q * adc;
	mult_d <= ref_dc * adc;
	adc_clip1 <= adc[15:4] == 12'h7ff || adc[15:4] == 12'h800;
end
wire signed [17:0] m_i = mult_i[32:15];
wire signed [17:0] m_q = mult_q[32:15];
wire signed [17:0] m_d = mult_d[32:15];

// It's OK to only extend sum registers with 2 high bits,
// because the values of the "LO" table are known, and relevant sets
// of six only sum(abs()) to 337616, less than half of 2^17*8
reg signed [19:0] sum_i, sum_q, sum_d;
reg signed [16:0] hold_i, hold_q, hold_dc;
reg clear_sum=0, strobe=0;
reg sum_c, hold_cl;  // clipping accumulation
always @(posedge clk) begin
	clear_sum <= phase==1 || phase==7;
	strobe <= clear_sum;
	sum_i <= $signed(clear_sum ? 20'd4 : sum_i) + m_i;
	sum_q <= $signed(clear_sum ? 20'd4 : sum_q) + m_q;
	sum_d <= $signed(clear_sum ? 20'd4 : sum_d) + m_d;
	sum_c <=        (clear_sum ? 0 : sum_c) | adc_clip1;
	if (clear_sum) begin
		hold_i <= sum_i[19:3];
		hold_q <= sum_q[19:3];
		hold_dc <= sum_d[19:3];
		hold_cl <= sum_c;
	end
end

assign stb = strobe;
assign sig_i = hold_i;
assign sig_q = hold_q;
assign sig_dc = hold_dc;
assign sig_cl = hold_cl;

// That was all easy, and easy to get wrong.
// Now cross-check be reconstructing what the ADC signal would
// be if it were all RF and DC, no noise or distortion.

reg signed [17:0] tone_i, tone_q;
// directly cut-and-pasted output of down_meta.py
always @(posedge clk) case (phase)
	 8: begin  tone_i <=   33924;  tone_q <=  126606;  end
	 9: begin  tone_i <=  -92682;  tone_q <=  -92682;  end
	10: begin  tone_i <=  126606;  tone_q <=   33924;  end
	11: begin  tone_i <= -126606;  tone_q <=   33924;  end
	 0: begin  tone_i <=   92682;  tone_q <=  -92682;  end
	 1: begin  tone_i <=  -33924;  tone_q <=  126606;  end
	 2: begin  tone_i <=  -33924;  tone_q <= -126606;  end
	 3: begin  tone_i <=   92682;  tone_q <=   92682;  end
	 4: begin  tone_i <= -126606;  tone_q <=  -33924;  end
	 5: begin  tone_i <=  126606;  tone_q <=  -33924;  end
	 6: begin  tone_i <=  -92682;  tone_q <=   92682;  end
	 7: begin  tone_i <=   33924;  tone_q <= -126606;  end
	default: begin  tone_i <= 18'bx;  tone_q <= 18'bx;  end
endcase

// OK to drop high bit, because our "LO" table is never full-scale negative
reg signed [32:0] tmul_i, tmul_q;
reg signed [15:0] tmul_dc;
always @(posedge clk) begin
	tmul_i <= tone_i * hold_i;
	tmul_q <= tone_q * hold_q;
	tmul_dc <= hold_dc;
end
wire signed [16:0] tm_i = tmul_i[32:16];
wire signed [16:0] tm_q = tmul_q[32:16];
wire signed [16:0] tm_dc = tmul_dc <<< 1;
reg signed [17:0] synth_l;
always @(posedge clk) synth_l <= tm_i + tm_q + tm_dc + 1;
wire signed [16:0] synth = synth_l >>> 1;

wire signed [15:0] adc_del;
reg_delay #(.dw(16), .len(10)) match(.clk(clk), .reset(1'b0),
	.gate(1'b1), .din(adc), .dout(adc_del));

reg signed [17:0] resid;
reg signed [33:0] resid2;
reg [36:0] sumsq;
reg [31:0] hold_sumsq;
reg clear_sum2=0, start_sqrt=0;
reg [1:0] stupid=0;  // internal state, only update rms every 18 cycles
always @(posedge clk) begin
	resid <= adc_del - synth;
	resid2 <= resid * resid;
	clear_sum2 <= (phase==0 || phase == 6) && stupid==0;
	if (clear_sum) stupid <= stupid==0 ? 2 : stupid-1;
	sumsq <= (clear_sum2 ? 37'd0 : sumsq) + resid2;
	if (clear_sum2) hold_sumsq <= sumsq[36:32] == 0 ? sumsq : 32'hffffffff;
	start_sqrt <= clear_sum2;
end

// In theory we should divide hold_sumsq by 18 first, otherwise it's
// rss not rms.  But since 18 is a constant, just absorb that into
// the definition of a sig_rms quantum.
wire sqrt_dv;
wire [15:0] sqrt_y;
isqrt #(.X_WIDTH(32)) sqrt(.clk(clk), .x(hold_sumsq),
	.en(start_sqrt), .y(sqrt_y), .dav(sqrt_dv));

reg [15:0] rms_r;
always @(posedge clk) if (sqrt_dv) rms_r <= sqrt_y;
assign sig_rms = rms_r;

endmodule
