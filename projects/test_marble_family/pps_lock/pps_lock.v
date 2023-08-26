`timescale 1ns / 1ns

// clk is suppsed to be the output of a quality VCXO,
// more-or-less White-Rabbit compatible, like the x5 output from
// the Taitien TXEAADSANF-25.000000 on Marble or Marble-Mini.
//
// If given a precise pps signal from e.g. a GPS, this module
// does the time comparison and emits a DAC value (dac_data)
// to phase lock the two.
//
// Initializing it takes a little sequencing; reference code
// for that is in lock_vcxo.py (should be nearby).
module pps_lock(
	input clk,
	input [1:0] pps_in,  // two bits via IDDR
	// (or just duplicate the pin if you don't have a DDR)
	input fir_enable,  // configuration of loop filter
	input run_request,
	input err_sign,  // choose sign of feedback
	input [15:0] dac_preset_val,
	// control signals to pass to ad5662
	output [15:0] dac_data,
	output dac_send,
	//
	output [13:0] dsp_status,
	output pps_tick,
	output pps_out
);

parameter count_period = 125000000;

// Rising-edge detect
// can make the debounce logic efficient later
reg pps_edge=0, pps_edge1=0, pps_edge2;
reg [1:0] pps1=0, pps2=0;
reg [25:0] pps_debounce=0;
reg pps_inhibit=0, pps_debounce_end=0;
wire pps_edge0 = (|pps1) & ~(|pps2) & ~pps_inhibit;
reg fine_phase=0;
always @(posedge clk) begin
	pps1 <= pps_in;
	pps2 <= pps1;
	pps_edge <= pps_edge0;
	pps_edge1 <= pps_edge;
	pps_edge2 <= pps_edge1;
	if (pps_edge0) pps_inhibit <= 1;
	// This setting of fine_phase is the whole point of using
	// an IDDR on the PPS input pin
	if (pps_edge0) fine_phase <= pps2[0];  // XXX tricky timing, check in simulation
	if (pps_inhibit) pps_debounce <= pps_debounce+1;
	pps_debounce_end <= pps_debounce == ((count_period>>2) - 2);
	if (pps_debounce_end) begin
		pps_debounce <= 0;
		pps_inhibit <= 0;
	end
end
// final output is pps_edge, pps_edge1, pps_edge2

// Actual 27-bit counter logic
reg [26:0] count=0;
wire count_init;  // defined later
reg end_of_count=0;
always @(posedge clk) begin
	end_of_count <= count == (count_period-2);
	count <= end_of_count ? 0 : count+1;
	if (count_init) count <= 1 << 11;
end
assign pps_tick = end_of_count;

// mode setting
// complicated
reg arm=0, run_req1=0, pd_overflow=0;
reg [12:0] phase_r=0;
reg count_active=0, dac_preset_stb=0, dsp_ready=0, dsp_strobe=0;
assign count_init = pps_edge & arm;
reg dsp_on=0;  // Final run status; internal errors will turn this off
always @(posedge clk) begin
	count_active <= (count[26:12] == 0) | arm;
	run_req1 <= run_request;
	if (run_request & ~run_req1) arm <= 1;
	dac_preset_stb <= count_init;
	if (count_init) begin
		arm <= 0;
		dsp_on <= 1;
	end
	if (pps_edge1) phase_r <= {count[11:0], fine_phase};
	pd_overflow <= pps_edge2 & ~count_active;
	if (~run_request | pd_overflow) dsp_on <= 0;
	if (pps_edge1 & dsp_on) dsp_ready <= 1;
	if (~count_active) dsp_ready <= 0;
	dsp_strobe <= dsp_ready & ~count_active;
end

// Instantiate the loop filter (PI controller)
wire dsp_ovf;
wire signed [12:0] phase_sign = phase_r ^ (1<<12);  // convert from offset binary to signed
wire signed [12:0] phase_dsp = phase_sign ^ {13{err_sign}};
pps_loop_filter plf(.clk(clk),
	.istrobe(dsp_strobe), .phase(phase_dsp),
	.fir_enable(fir_enable),
	.dac_preset_stb(dac_preset_stb), .dac_preset_val(dac_preset_val),
	.overflow(dsp_ovf),
	.dac_stb(dac_send),
	.dac_val(dac_data)
);
assign pps_out = count_active;  // not phase-aligned with pps_in
// The 12-bit representation of phase_r is pretty deeply baked
// into the upper firmware and software layesrs.
// Since the actual value is 13 bits now, and I'm more interested
// in jitter than large-swing transients, I choose the lsb.
// The equilibrium point that I got used to at 2048 will now be at 0.
assign dsp_status = {dsp_on, arm, phase_r[11:0]};

endmodule
