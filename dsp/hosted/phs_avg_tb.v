`timescale 1ns / 1ns

`define ADDR_HIT_dut_kx 0
`define ADDR_HIT_dut_ky 0

`define LB_DECODE_phs_avg_tb
`include "phs_avg_tb_auto.vh"

module phs_avg_tb;

parameter dwi = 17;
parameter dwj = 16;

reg clk;
reg fail=0;
integer cc;
initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("phs_avg.vcd");
        $dumpvars(5,phs_avg_tb);
    end
    for (cc=0; cc<450; cc=cc+1) begin
        clk=0; #5;
        clk=1; #5;
    end
    if (~fail) begin
        $display("PASS");
        $finish();
    end else begin
        $display("### Check code for bit-width incompatibility ###");
        $display("##################################################");
        $display("FAIL");
        $stop();
    end
end

// Output file (if any) for dumping the results
integer out_file;
reg [255:0] out_file_name;
initial begin
    out_file = 0;
    if ($value$plusargs("out_file=%s", out_file_name))
        out_file = $fopen(out_file_name,"w");
end

reg signed [dwi-1:0] x=0;
reg signed [dwi-1:0] y=0;
reg [2:0] state=0;
wire iq=state[0];
reg reset = 0;
always @(posedge clk) begin
    state <= state+1;
    if (cc<5) reset <= 1;
    else reset <= 0;
    if (cc<425) begin
        x  <= ~iq ? 32000 : 600;
        y  <= ~iq ? 32000 : 500;
    end else begin
        x <= 0;
        y <= 0;
end
end

// Local bus (not used in this test bench)
wire lb_clk=clk;
reg signed [31:0] lb_data;
reg [15:0] lb_addr;
reg lb_write=0;

`AUTOMATIC_decode

wire signed [dwi+1:0] z;
wire signed [dwi+7:0] sum_filt;
phs_avg dut // auto
    (.clk(clk), .reset(reset), .iq(iq), .x(x), .y(y), .sum_filt(sum_filt), .z(z), `AUTOMATIC_dut);

// Set control registers from command line
// See also lp_setup in lp_notch_test.py
reg signed [dwj-1:0] kxr, kxi, kyr, kyi;
initial begin
    if (!$value$plusargs("kxr=%d", kxr)) kxr = 1000;
    if (!$value$plusargs("kxi=%d", kxi)) kxi = 100;
    if (!$value$plusargs("kyr=%d", kyr)) kyr = -1000;
    if (!$value$plusargs("kyi=%d", kyi)) kyi = 200;
    #1;
    dp_dut_kx.mem[0] = kxr;  // k_X  real part
    dp_dut_kx.mem[1] = kxi;  // k_X  imag part
    dp_dut_ky.mem[0] = kyr;  // k_Y  real part
    dp_dut_ky.mem[1] = kyi;  // k_Y  imag part
end

// Write a comprehensible output file
// One line per pair of clock cycles
// Also gives the timing diagram something comprehensible to look at and graph
reg signed [dwi+1:0] z1=0;
reg signed [dwi-1:0] y1=0, y_i=0, y_q=0;
reg signed [dwi-1:0] x1=0, x_i=0, x_q=0;
always @(posedge clk) begin
    x1 <= x;
    y1 <= y;
    z1 <= z;  // only imag number
    if (~iq) y_i <= y1;
    if (~iq) y_q <= y;
    if (~iq) x_i <= x1;
    if (~iq) x_q <= x;
    if (out_file != 0 && ~iq) $fwrite(out_file," %d %d %d %d %d\n", x_i, x_q, y_i, y_q, z1);
end

// to check the bit-width
reg signed [dwj-1:0] kx_i=0, ky_i=0;
always @(posedge clk) begin
    kx_i  <= dut.kx;
    ky_i  <= dut.ky;
end
// get the parity bit to compare
wire xmul_val = (~^kx_i != ~^dut.kx1);
wire ymul_val = (~^ky_i != ~^dut.ky1);

always @(posedge clk) begin
    if (xmul_val || ymul_val) fail = 1;
end

endmodule
