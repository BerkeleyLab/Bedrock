`timescale 1ns / 1ps

module phasex_tb;

parameter FREQ1          =   238.0;         // MHz
parameter F_RATIO        =   2;
parameter FREQ2          =   FREQ1/F_RATIO; // MHz
parameter REF_FREQ       =   200.0;         // MHz
parameter MAX_CC         =   5300;
parameter DW             =   16;
parameter UCLK1_DELAY_UI =   0.1;        // UI

localparam FULL_RANGE    =   1<<DW;
localparam UCLK1_PERIOD  =   1e3/FREQ1;
localparam UCLK2_PERIOD  =   1e3/FREQ2;
localparam SCLK_PERIOD   =   1e3/REF_FREQ;
localparam ADV           =   FREQ1/F_RATIO * FULL_RANGE/REF_FREQ;
// adv: phase advances per sclk cycle to lock to uclk

reg rclk;
integer cc, errors=0;

reg signed [DW-1:0] phase_expect;
wire signed [DW-1:0] phase_diff;

initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("phasex.vcd");
        $dumpvars(5,phasex_tb);
    end
    for (cc=0; cc<MAX_CC; cc=cc+1) begin
        rclk=0; #5;
        rclk=1; #5;
    end
    $display("ADV: %d, Expected phase: %d, Measured phase: %d",
        ADV, phase_expect, phase_diff);
    if (errors == 0) begin
        $display("PASS");
        $finish();
    end else begin
        $display("FAIL");
        $stop();
    end
end

reg uclk1=1, uclk2=1, sclk=1;
real period_delay;
initial forever #(UCLK2_PERIOD/2) uclk2 = ~uclk2;
initial begin
    period_delay = UCLK1_DELAY_UI;
    $display("period_delay: %.4f UI", period_delay);
    phase_expect = -period_delay * FULL_RANGE / F_RATIO;
    #(UCLK1_PERIOD * period_delay);
    forever #(UCLK1_PERIOD/2) uclk1 = ~uclk1;
end
initial begin
    #($urandom_range(200, 100));
    forever #(SCLK_PERIOD/2) sclk = ~sclk;
end

// device under test
wire [DW:0] vfreq_out;
wire dval;
phase_diff #(
    .adv(ADV), .order1(F_RATIO), .order2(1), .dw(DW+1)
) track (
    .uclk1      (uclk1),
    .ext_div1   (1'b0),
    .uclk2      (uclk2),
    .ext_div2   (1'b0),
    .sclk       (sclk),
    .rclk       (rclk),
    .phdiff_out (phase_diff),
    .vfreq_out  (vfreq_out),
    .dval       (dval)
);

reg phase_pass=0;
real err_bar = 0.02;
reg signed [DW-1:0] phase_err=0;
// Readout display
always @(negedge rclk) begin
    if (dval) begin     // needs to wait when DW>=16
        phase_err = phase_diff - phase_expect;
        phase_pass = $abs(phase_err)/FULL_RANGE < err_bar;
        // $display("cc: %d, phase_err: %d, pass: %d", cc, phase_err, phase_pass);
        if (~phase_pass) errors = errors+1;
    end
end

endmodule
