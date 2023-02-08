`timescale 1ns / 1ns
`include "constants.vams"

module iq_trace_tb;

reg clk;
integer cc;
reg trace;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("iq_trace.vcd");
		$dumpvars(5,iq_trace_tb);
	trace = $test$plusargs("trace");
	end
	for (cc=0; cc<1800; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("WARNING: Not a self-checking testbench. Will always pass.");
	$finish("PASS");
end

integer num=7;
integer den=33;
reg [5:0] th=0;
wire [5:0] thn = th+num;
always @(posedge clk) th <= (thn >= den) ? thn-den : thn;

real x0, x1;
integer c0, c1;
reg signed [15:0] v0=0, v1=0;
always @(posedge clk) begin
	x0 = 32767.0*$cos(th*`M_TWO_PI/den);
	c0 = $floor(x0+0.5);
	v0 <= c0 > 32767 ? 32767 : c0 < -32767 ? -32767 : c0;
	x1 = 10000.0*$cos(th*`M_TWO_PI/den);
	c1 = $floor(x1+0.5);
	v1 <= c1 > 32767 ? 32767 : c1 < -32767 ? -32767 : c1;
end

// checked:
//   cic_period   cic_shift
//      33           7  (9 is also OK)
//      66           9
//     132          11
//     264          13
//     528          15

parameter nadc = 4;
parameter dw = 16; // don't change this
parameter ow = 36; // follows the rule in ccfilt: 18+2*log2(max(cic_period))
parameter aw = 4; // ridiculously small
reg [19:0] phase_step_h = 222425;
reg [11:0] phase_step_l = 868;
reg [11:0] modulo       = 4;
reg [17:0] lo_amp       = 74843;  // don't subtract epsilon yet
reg [12:0] cic_period   = 33;
reg [ 3:0] cic_shift    = 7;
reg [nadc-1:0] keep = 4'b1010; // {nadc{1'b1}};
reg reset=0;
reg trig=0;
reg [1:0] trig_mode=0;
wire [aw+1:0] ro_addr;
wire ro_ack;

wire [18:0] phase;
ph_acc ph_acc(.clk(clk), .reset(reset), .en(1'b1), .phase_acc(phase),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo)
);

// CORDIC to generate sin and cos from phase
wire signed [17:0] cosa, sina;
cordicg_b22 #(.width(18), .nstg(20), .def_op(0)) i_cordicg_b22 (.clk(clk), .opin(2'b00),
	      .xin(lo_amp), .yin(18'd0), .phasein(phase),
	      .xout(cosa), .yout(sina), .phaseout()
);

wire ro_enable;
wire [31:0] ro_data;
iq_trace #(.dw(dw), .ow(ow), .nadc(nadc), .aw(aw)) dut(
	.clk(clk), .reset(reset), .trig(trig), .trig_mode(trig_mode),
	.adcs({16'b0,v1,v0,v0}),
	.cosa(cosa), .sina(sina),
	.cic_period(cic_period), .cic_shift(cic_shift),
	.keep(keep),
	.ro_clk(clk), .ro_addr(ro_addr),
	.ro_data(ro_data),
	.ro_enable(ro_enable), .ro_ack(ro_ack)
);

real z_i, z_q, mag_out;
always @(*) begin
	z_i = (dut.result_i+1.0)/524288.0;
	z_q = (dut.result_q+1.0)/524288.0;
	mag_out = $sqrt(z_i*z_i+z_q*z_q);
end


reg [aw+1:0] readout_ctr=0;
assign ro_ack = &readout_ctr;
always @(posedge clk) begin
	if (ro_enable) readout_ctr <= readout_ctr+1;
	if (cc == 700) trig_mode <= 1;
	trig <= cc==1100;
end
assign ro_addr = {2'b00, readout_ctr[aw+1:2]};
always @(negedge clk) if (trace) $display("%x %x",ro_addr,ro_data);

endmodule
