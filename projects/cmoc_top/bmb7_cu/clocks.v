`timescale 100 ps / 10 ps

module clocks (
    input rst,
    input sysclk_buf,
    output clk_eth,
    output clk_eth_90,
    output pll_lock,
    output clk_1x_90,
    output clk_2x_0,
    output mmcm_lock
);
    parameter clkin_period = 5;  // PLLE2_BASE CLKIN1_PERIOD in ns. default 200MHz input.
    parameter pll_mult = 5;
    parameter pll_div = 8;
    parameter mmcm_mult = 6;
    parameter mmcm_div0 = 16;
    parameter mmcm_div1 = 8;

wire pll_clkfb;
wire pll_clk_0, pll_clk_90;
wire mmcm_clkfbout, mmcm_clkfbin;
wire clk_1x_int, clk_2x_int;

`ifdef SIMULATE

assign clk_2x_0 = sysclk_buf;
reg clk_r=0;
always @(negedge clk_2x_0) clk_r <= #1.25 ~clk_r;
assign clk_1x_90 = clk_r;
assign clk_eth = clk_r;

`else

PLLE2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKIN1_PERIOD(clkin_period),
    .CLKFBOUT_MULT(pll_mult),
    .DIVCLK_DIVIDE(1),
    .CLKFBOUT_PHASE(0.0),
    .CLKOUT0_DIVIDE(pll_div),  .CLKOUT0_DUTY_CYCLE(0.5), .CLKOUT0_PHASE( 0.0), // 125 MHz
    .CLKOUT1_DIVIDE(pll_div),  .CLKOUT1_DUTY_CYCLE(0.5), .CLKOUT1_PHASE(90.0), // 125 MHz
    .REF_JITTER1(0.0),
    .STARTUP_WAIT("FALSE")
)
PLLE2_BASE_inst (
    .CLKIN1(sysclk_buf),
    .CLKOUT0(pll_clk_0),        // 125 MHz, 0 degree
    .CLKOUT1(pll_clk_90),       // 125 MHz, 90 degree
    .CLKFBOUT(pll_clkfb),
    .LOCKED(pll_lock),
    .PWRDWN(1'b0),
    .RST(rst),
    .CLKFBIN(pll_clkfb)
);

BUFG clk_eth_bufg (.I(pll_clk_0), .O(clk_eth));
BUFG clk_eth_90_bufg (.I(pll_clk_90), .O(clk_eth_90));


MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT_F(mmcm_mult), .CLKFBOUT_PHASE(0.0),     // 200 x 6 = 1200
    .CLKIN1_PERIOD(clkin_period),
    .CLKOUT0_DIVIDE_F(mmcm_div0), .CLKOUT0_DUTY_CYCLE(0.5), .CLKOUT0_PHASE(90.0),  // 1200/16 = 75MHz
    .CLKOUT1_DIVIDE(mmcm_div1), .CLKOUT1_DUTY_CYCLE(0.5), .CLKOUT1_PHASE(0.0),     // 1200/8 = 150MHz
    .CLKOUT4_CASCADE("FALSE"),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.0),
    .STARTUP_WAIT("FALSE")
) MMCME2_BASE_inst (
    .CLKOUT0(clk_1x_int),
    .CLKOUT1(clk_2x_int),
    .CLKFBOUT(mmcm_clkfbout),
    .LOCKED(mmcm_lock),
    .CLKIN1(sysclk_buf),
    .PWRDWN(1'b0),
    .RST(rst),
    .CLKFBIN(mmcm_clkfbin)
);

BUFG clkfbout_bufg (
    .O(mmcm_clkfbin),
    .I(mmcm_clkfbout)
);

BUFG clk_75_bufg (.I(clk_1x_int), .O(clk_1x_90));
BUFG clk_150_bufg (.I(clk_2x_int), .O(clk_2x_0));

`endif // `define SIMULATE
endmodule
