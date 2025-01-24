// -------------------------------------------------------------------------------
// -- Title      : General spartan6 clocks generation
// -- Project    : LLRF
// -------------------------------------------------------------------------------
// -- File Name  : spartan6_clocks.v
// -- Author     : Qiang Du
// -- Company    : LBNL
// -- Created    : 10-03-2014
// -- Last Update: 10-03-2014 15:36:52
// -- Standard   : Verilog
// -------------------------------------------------------------------------------
// -- Description:
// -------------------------------------------------------------------------------
// -------------------------------------------------------------------------------
// -- Copyright (c) LBNL
// -------------------------------------------------------------------------------

`timescale 100 ps / 10 ps
module spartan6_clocks(
    input rst,
    input sysclk_p,
    input sysclk_n,
    output clk_eth,
    output clk_1x_90,
    output clk_2x_0,
    output pll_lock
);
    parameter clkin_period = 5;
    parameter dcm_mult = 5;
    parameter dcm_div = 8;
    parameter plladv_mult = 5;
    parameter plladv_div0 = 16;
    parameter plladv_div1 = 8;

wire xclk125_buf, clk_int_buf, clk_int;
wire sysclk_buf;
wire pll_clkfb;

`ifdef SIMULATE

assign clk_2x_0 = sysclk_p;
reg clk_r=0;
always @(negedge clk_2x_0) clk_r <= #1.25 ~clk_r;
assign clk_1x_90 = clk_r;
assign clk_eth = clk_r;

`else

IBUFGDS #(
    .DIFF_TERM("FALSE"),
    .IBUF_DELAY_VALUE("0"),
    .IOSTANDARD("LVDS_25")
) inibufgds (
    .O(sysclk_buf),
    .I(sysclk_p),
    .IB(sysclk_n)
);

//---------- 125 MHz TX clock ----------
DCM_SP #(
  .CLKDV_DIVIDE(4.0),
  .CLKFX_DIVIDE(dcm_div),            // Can be any integer from 1 to 32
  .CLKFX_MULTIPLY(dcm_mult),          // Can be any integer from 2 to 32
  .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
  .CLKIN_PERIOD(clkin_period),          // Specify period of input clock
  .CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
  .CLK_FEEDBACK("1X"),         // Specify clock feedback of NONE, 1X or 2X
  .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
  .DLL_FREQUENCY_MODE("HIGH"),  // HIGH or LOW frequency mode for DLL
  .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
  .PHASE_SHIFT(0),              // Amount of fixed phase shift from -255 to 255
  .STARTUP_WAIT("FALSE")        // Delay configuration DONE until DCM LOCK, TRUE/FALSE
) DCM_SP_clk125tx (
  .CLKFX(xclk125_buf), // DCM CLK synthesis out (M/D)
  .CLKFB(clk_eth),     // DCM clock feedback
  .CLKIN(clk_int),     // Clock input (from IBUFG, BUFG or DCM)
  .PSCLK(1'b0),       // Dynamic phase adjust clock input
  .PSEN(1'b0),        // Dynamic phase adjust enable input
  .PSINCDEC(1'b0),    // Dynamic phase adjust increment/decrement
  .RST(rst) // DCM asynchronous reset input
);
BUFG bufg125_tx(.I(xclk125_buf), .O(clk_eth));

PLL_ADV #(
    .SIM_DEVICE("SPARTAN6"),
    .BANDWIDTH("OPTIMIZED"),
    .CLKIN1_PERIOD(clkin_period),
    .CLKFBOUT_MULT(plladv_mult), // 200x5=1000
    .DIVCLK_DIVIDE(1),
    .CLKFBOUT_PHASE(0.0),
    .CLKOUT0_DIVIDE(plladv_div0),  .CLKOUT0_DUTY_CYCLE(0.5), .CLKOUT0_PHASE(90.0), // 62.5 MHz
    .CLKOUT1_DIVIDE(plladv_div1),  .CLKOUT1_DUTY_CYCLE(0.5), .CLKOUT1_PHASE( 0.0), // 125 MHz
    .CLKOUT2_DIVIDE(plladv_mult),  .CLKOUT2_DUTY_CYCLE(0.5), .CLKOUT2_PHASE( 0.0), // 200 MHz
    .REF_JITTER(0.005),
    .COMPENSATION("SYSTEM_SYNCHRONOUS")
) PLL_ADV_inst (
    .CLKINSEL(1'b1),
    .CLKIN1(sysclk_buf),
    .CLKOUT0(clk_1x_buf),        // 62.5 MHz, 90 degree
    .CLKOUT1(clk_2x_buf),      // 125 MHz,  0 degree
    .CLKOUT2(clk_int_buf),      // 200 MHz,  0 degree
    .CLKFBOUT(pll_clkfb),
    .LOCKED(pll_lock),
    .DADDR(5'b0),
    .DCLK(1'b0),
    .DEN(1'b0),
    .DI(16'b0),
    .DWE(1'b0),
    .REL(1'b0),
    .RST(rst),
    .CLKFBIN(pll_clkfb)
);

BUFG clk_1x_bufg (.I(clk_1x_buf), .O(clk_1x_90));
BUFG clk_2x_bufg (.I(clk_2x_buf), .O(clk_2x_0));
BUFG clk_200_bufg (.I(clk_int_buf), .O(clk_int));
`endif // `define SIMULATE
endmodule
