`timescale 1ns / 1ns

`define ADDR_HIT_dut_amp 0
`define ADDR_HIT_dut_wth 0

`define LB_DECODE_pulse_drive_tb
`include "pulse_drive_tb_auto.vh"

module pulse_drive_tb;

localparam SIM_STOP=160000;
localparam ADC_CLK_CYCLE=10.606;
reg clk;
integer cc;
reg trace;
reg [10:0] bunch_arrival_delay=0;
integer delay_int;
integer out_file;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("pulse_drive.vcd");
		$dumpvars(5,pulse_drive_tb);
	end
	if ($test$plusargs("trace")) begin
		trace = 1;
		out_file = $fopen("pulse_drive.dat", "w");
	$fwrite(out_file, "# bunch_arrival_trig, dut_amp, dut_wth, dut.tri_out_xy");
	end
	if (!$value$plusargs("delay=%d", delay_int)) delay_int = 0;
	bunch_arrival_delay = delay_int[10:0];
	for (cc=0; cc < SIM_STOP; cc=cc+1) begin
		clk=0; #(ADC_CLK_CYCLE/2);
		clk=1; #(ADC_CLK_CYCLE/2);
	end
	$display("PASS");
	$finish();
end
reg [2:0] state=0;
wire iq=state[0];
always @(posedge clk) state <= state+1;

// Stub clk1x local bus to keep newad happy
// We actually set register values directly with Verilog dot notation,
// without cycling this bus.
wire clk1x_clk = clk;  // actually important so dprams can be accessed correctly
wire [31:0] clk1x_data=0;
wire [23:0] clk1x_addr=0;
wire clk1x_write=0;

// newad
`AUTOMATIC_decode
reg bunch_arrival_trig=0;
wire signed [17:0] tri_out_xy;
pulse_drive dut  // auto clk1x
	(.clk(clk),
	 .iq(iq),
	 .bunch_arrival_trig(bunch_arrival_trig),
	 .tri_out_xy(tri_out_xy),
	 `AUTOMATIC_dut
);

reg signed [17:0] ampx, ampy;
reg [6:0] width;
initial begin
	if (!$value$plusargs("ampx=%d", ampx)) ampx = 1 << 10;
	if (!$value$plusargs("ampy=%d", ampy)) ampy = 1 << 4;
	if (!$value$plusargs("width=%d", width)) width = 10;
	#1;
	dp_dut_amp.mem[0] = ampx;
	dp_dut_amp.mem[1] = ampy;
	dut_wth = width;
end

// for 1 MHz rep rate:
// bunch trigger comes very (1400/1300)*(1320/14) = 1320/13 adc_clk cycles
// step_l = 13, modulo = 4096 - 1320
// for 100 kHz rep rate:
// bunch trigger comes every (14000/1300)*(1320/14) = 13200/13 adc_clk cyles
// for 10 kHz rep rate:
// bunch trigger comes every (140000/1300)*(1320/14) = 132000/13 adc_clk cyles
// this now non-binary, like the ph_acc.v
reg bunch_arrival_trig_x=0;
// initial 100 kHz option
localparam integer STEP_L = 13;
localparam integer MODULO_100K = (1 << 18) - 13200;
localparam integer MODULO_10K = (1 << 18) - 132000;
reg [17:0] phase_l=0;
reg carry=0;
// XXX there is weirdly large delay while transitioning btw rep_rate
reg rep_state=1'b0;  // 0: 100 kHz, 1: 10 kHz
integer switch_rep_rate = 0;
localparam MIN_SWITCH = 1;
localparam MAX_SWITCH = 3;
task randomize_rep_rate;
        switch_rep_rate = MIN_SWITCH + ($urandom % (MAX_SWITCH - MIN_SWITCH + 1));
endtask
initial begin
        randomize_rep_rate();
end
always @(posedge bunch_arrival_trig_x) begin
        if (switch_rep_rate == 0) begin
            rep_state <= ~rep_state;
            randomize_rep_rate();
	    phase_l <= 0;
	    carry <= 0;
	end else switch_rep_rate <= switch_rep_rate - 1;
end

// Bresenham's algorithm with dynamic parameters
integer modulo=0;
always @(posedge clk) begin
	if (rep_state) modulo = MODULO_10K;
	else modulo = MODULO_100K;
	{carry, phase_l} <= (carry ? modulo : 18'd0) + phase_l + STEP_L;
	bunch_arrival_trig_x <= carry;
end

// this is from timing_pulse_gen.v
// optional programmable delay of bunch_arrival_trig_x, max is (2**bitwidth(bunch_arrival_delay)-1)
// max available delay = (2**11)-1 clock cycles
// ((2**11)-1)*(14/1320e6) = 21.7 us
reg [2047:0] bunch_arrival_trig_shift=0;
always @(posedge clk) begin
        bunch_arrival_trig_shift <= {bunch_arrival_trig_shift[2046:0], bunch_arrival_trig_x};
        bunch_arrival_trig <= bunch_arrival_trig_shift[bunch_arrival_delay];
end

always @(negedge clk) if (trace) begin
         $fwrite(out_file, "%d %d %d %d\n",
                 bunch_arrival_trig, dut_amp, dut_wth, dut.tri_out_xy);
end

endmodule
