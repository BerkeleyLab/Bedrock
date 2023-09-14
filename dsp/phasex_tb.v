`timescale 1ns / 1ps

module phasex_tb;
parameter FREQ1         =   500.0*11/12/4; // MHz
parameter F_RATIO       =   1;             // FREQ1/FREQ2
parameter FREQ2         =   FREQ1/F_RATIO; // MHz
parameter REF_FREQ      =   200.0;         // MHz

parameter UCLK1_PERIOD  =   1e3/FREQ1;
parameter UCLK2_PERIOD  =   1e3/FREQ2;
parameter SCLK_PERIOD   =   1e3/REF_FREQ;
parameter MAX_CC        =   3300;
parameter DW            =   14;
parameter ADV           =   FREQ1/REF_FREQ/2/F_RATIO*(1<<DW);
// adv: phase advances per sclk cycle to lock to uclk

parameter EXT_DIV1 = F_RATIO-1;
real period_delay;
reg rclk;
reg trace;
integer cc, errors=0;

reg [DW-2:0] phase_expect;
wire [DW-2:0] phase_diff;

initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("phasex.vcd");
        $dumpvars(5,phasex_tb);
    end
    trace = $test$plusargs("trace");
    for (cc=0; cc<MAX_CC; cc=cc+1) begin
        rclk=0; #5;
        rclk=1; #5;
    end
    $display("ADV: %d", ADV);
    $display("Expected phase: %d, Calculated phase: %d",
        phase_expect, phase_diff);
    if (errors == 0) begin
        $display("PASS");
        $finish(0);
    end else begin
        $display("FAIL");
        $stop(0);
    end
end

reg uclk1=0, uclk2=0, sclk=0;
initial forever #(UCLK1_PERIOD/2) uclk1 = ~uclk1;
initial begin
    period_delay = 0.517;
    $display("period_delay: %.4f UI", period_delay);
    phase_expect = period_delay * (1<<(DW-1)) / F_RATIO + (1<<(DW-2))*EXT_DIV1*1.5;
    phase_expect = phase_expect % 8193;
    #(UCLK1_PERIOD * period_delay);
    forever #(UCLK2_PERIOD/2) uclk2 = ~uclk2;
end
initial forever #(SCLK_PERIOD/2) sclk = ~sclk;

// Start command
reg trig=0;
always @(posedge rclk) trig <= cc==12;

// Readout process
reg f=0, f1=0, done=0;
reg [5:0] raddr=0;
always @(posedge rclk) begin
    f <= cc>150 && ready;
    if (&raddr) done <= 1;
    if (f & ~done) raddr <= raddr+1;
    f1 <= f & ~done;
end

// Device under test
wire ready;
wire [15:0] dout;
phasex #(.aw(6)) dut(
    .uclk1  (uclk1),
    .uclk2  (uclk2),
    .sclk   (sclk),
    .rclk   (rclk),
    .trig   (trig),
    .ready  (ready),
    .addr   (raddr),
    .dout   (dout));

reg [1:0] qphase=0;
always @(posedge uclk1) qphase <= qphase + 1'b1;

// Second device under test
wire [DW-1:0] vfreq_out;
wire dval;
integer adv = $floor(ADV);
phase_diff #(
    .ext_div1_en(EXT_DIV1),
    .ext_div2_en(0),
    .adv(ADV), .order1(F_RATIO), .order2(1), .dw(DW), .delta(33)
) track (
    .uclk1      (uclk1),
    .ext_div1   (qphase[1]),
    .uclk2      (uclk2),
    .ext_div2   (1'b0),
    .sclk       (sclk),
    .rclk       (rclk),
    .phdiff_out (phase_diff),
    .vfreq_out  (vfreq_out),
    .dval       (dval)
);

reg phase_pass=0, freq_pass=0;
real err_bar = 0.02;
reg signed [DW-2:0] phase_err=0;
// Readout display
always @(negedge rclk) begin
    if (trace & f1) $display("%x %d %x", dout, phase_diff, vfreq_out);

    if (dval) begin
        phase_err = $signed(phase_diff - phase_expect);
        // $display("phase_err: %d", phase_err);
        phase_pass = $abs(phase_err) < 8193*err_bar;
        if (~phase_pass) errors = errors+1;
    end
end

endmodule
