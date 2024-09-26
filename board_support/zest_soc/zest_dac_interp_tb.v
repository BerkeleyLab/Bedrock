`timescale  1ns/1ps
`define DSP_CLK_CYCLE 8

module zest_dac_interp_tb;
parameter integer DW = 14;
parameter real coeff_r = -1.279;     // adjust me. 1 for normal interp : y1=(y0+y2)/2.
localparam integer LATENCY = 8;
localparam [DW:0] DAC_INTERP_COEFF = coeff_r / 2 * (2**DW);

integer cc=0;
reg dac_clk=1, dsp_clk=1;
reg pass=1;
initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("zest_dac_interp.vcd");
        $dumpvars(5,zest_dac_interp_tb);
    end
    $display("%4s %8s %8s %8s %6s",
        "cc", "data_dsp", "data_dac", "expected", "result");
    $display("--------------------------------------");
    for (cc=0; cc<=21; cc=cc+1) begin
        dac_clk = 1; #(`DSP_CLK_CYCLE/4);
        dac_clk = 0; #(`DSP_CLK_CYCLE/4);
    end
    if (pass) $finish();
    else $stop();
end
always #(`DSP_CLK_CYCLE/2) dsp_clk = ~dsp_clk;

// reg signed [DW-1:0] coeff = coeff_r * 2**DW;
reg signed [DW-1:0] data_dsp={DW{1'bx}};
wire signed [DW-1:0] data_dac;

zest_dac_interp #(.DW(DW)) dut(
    .dsp_clk        (dsp_clk),
    .din            (data_dsp),
    .coeff          (DAC_INTERP_COEFF),
    .dac_clk        (dac_clk),
    .dout           (data_dac)
);

// Verification logic
// find expectations
wire signed [DW-1:0] data_dsp_delay;
reg_delay #(.dw(DW), .len(LATENCY)) delay1 (
    .clk    (dac_clk),
    .reset  (1'b0),
    .gate   (1'b1),
    .din    (data_dsp),
    .dout   (data_dsp_delay)
);

reg signed [DW-1:0] d1=0;
always @(posedge dsp_clk) d1 <= data_dsp;
wire signed [DW-1:0] data_interp = (d1 + data_dsp) / 2 * coeff_r;
wire signed [DW-1:0] data_interp_delay;

reg_delay #(.dw(DW), .len(LATENCY-1)) delay2 (
    .clk    (dac_clk),
    .reset  (1'b0),
    .gate   (1'b1),
    .din    (data_interp),
    .dout   (data_interp_delay)
);
wire signed [DW-1:0] data_exp = dut.tick ? data_interp_delay : data_dsp_delay;

initial begin
    @(posedge dsp_clk) data_dsp <= 200;
    @(posedge dsp_clk) data_dsp <= 400;
    @(posedge dsp_clk) data_dsp <= -500;
    @(posedge dsp_clk) data_dsp <= 700;
end

wire signed [DW-1:0] err = data_dac - data_exp;
always @(negedge dac_clk) begin
    if (cc >=LATENCY+2 ) pass &= $abs(err) <= 1;
    $display("%4d %8d %8d %8d %6s",
        cc, data_dsp, data_dac, data_exp, pass?"PASS":"FAIL");
end

endmodule