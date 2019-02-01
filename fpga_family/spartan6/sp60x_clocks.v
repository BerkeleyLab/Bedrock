`timescale  100 ps / 10 ps
//-------------------------------------
// sp60x_clocks.v
// Chip Lukes
//-------------------------------------
// History of Changes:
//  5-05-2009 CJL: created
//  6-15-2009 JAD: Added PLL to generate MCB clocks, also used PLL to generate some others.
//  6-29-2010 LRD: Disabled PHY_RXCLK, clean up whitespace and capitalization, rename
//  6-28-2012 QDU: change parameter to "mult" and "divide" to give arbitrary output frequency.
//                 add parameter "diff_input" to select clock input channel.
//-------------------------------------
// This module contains all of the clock related stuff
// Applies to both SP601 and SP605
// and Avnet Spartan-6 LX150T
//-------------------------------------
//
module sp60x_clocks(

// Differential sys clock
input    wire        SYSCLK_P,SYSCLK_N,
// Single-ended sys clock
input    wire        SYSCLK,
output    wire        CLK25,      // 25 MHz
output    wire        CLK_PLLOUT,     // 200 MHz
output    wire        PROC_CLK,   // Processing Clock (200 MHz?)
output    wire        CLK125,     // 125 MHz

// Master Clock for memory controller block
output    wire        MCBCLK_2X_0,     // CLKOUT0 from PLL @ 800 MHz
output    wire        MCBCLK_2X_180,   // CLKOUT1 from PLL @ 800 MHz, 180 degree phase
output    wire        MCBCLK_PLL_LOCK, // from PLL
output    wire        CALIB_CLK,       // GCLK.  MIN = 50MHz, MAX = 100MHz.

// 125 MHz clocks (from PHY RXCLK)
//input    wire        PHY_RXCLK,
//output   wire        CLK125_RX,   // 125 MHz

input    wire        RST // system reset - resets PLLs, DCM's

);
parameter   clk1_period = 5;  // PLL_ADV CLKIN1_PERIOD in ns. default 200MHz input.
parameter   clk2_period = 10; // PLL_ADV CLKIN2_PERIOD in ns. default 200MHz input.
parameter   mult = 4; // PLL_ADV CLKFB_OUT_MULT.
parameter   divide_out = 4;// PLL_ADV CLKOUT5_DIVIDE
parameter   divide_proc = 8;// PLL_ADV CLKOUT5_DIVIDE
parameter   diff_input = 1'b1; // select CLKINSEL

`ifndef SIMULATE
/* System Clock */
// IBUFG the raw clock input1
wire                osc_clk_ibufgds;
IBUFGDS #(
  .DIFF_TERM("FALSE"),    // Differential Termination (Virtex-4/5, Spartan-3E/3A)
  .IBUF_DELAY_VALUE("0"), // Specify the amount of added input delay for
                          //   the buffer, "0"-"16" (Spartan-3E/3A only)
  .IOSTANDARD("LVDS_25")  // Specify the input I/O standard
) inibufgds (
  .O(osc_clk_ibufgds),  // Clock buffer output
  .I(SYSCLK_P),       // Diff_p clock buffer input (connect directly to top-level port)
  .IB(SYSCLK_N)       // Diff_n clock buffer input (connect directly to top-level port)
);

// IBUFG the raw clock input2
wire                osc_clk_ibufg;
IBUFG inibufg (.I(SYSCLK), .O(osc_clk_ibufg));

	wire    clk25_bufg_in, calib_clk_bufg_in, clkout_bufg_in, proc_clk_bufg_in; // raw PLL outputs
	BUFG clk25_bufg     (.I(clk25_bufg_in),     .O(CLK25) );
	BUFG calib_clk_bufg (.I(calib_clk_bufg_in), .O(CALIB_CLK) );
	BUFG clk200_bufg    (.I(clkout_bufg_in),    .O(CLK_PLLOUT) );
	BUFG proc_clk_bufg  (.I(proc_clk_bufg_in),  .O(PROC_CLK) );


	wire    clkfbout_clkfbin; // Clock from PLLFBOUT to PLLFBIN
	PLL_ADV #
		(
		.BANDWIDTH          ("OPTIMIZED"),
		.CLKIN1_PERIOD      (clk1_period), // 200 MHz = 5ns
		.CLKIN2_PERIOD      (clk2_period),
		.DIVCLK_DIVIDE      (1),
		.CLKFBOUT_MULT      (mult), // 200 MHz x4 = 800 MHz
		.CLKFBOUT_PHASE     (0.0),
		.CLKOUT0_DIVIDE     (1), // 800 MHz /1  = 800 MHz
		.CLKOUT1_DIVIDE     (1), // 800 MHz /1  = 800 MHz
		.CLKOUT2_DIVIDE     (32),// 800 MHz /32 = 25 MHz
		.CLKOUT3_DIVIDE     (16),// 800 MHz /16 = 50 MHz
		.CLKOUT4_DIVIDE     (divide_out), // 800 MHz /4  = 200 MHz
		.CLKOUT5_DIVIDE     (divide_proc), // 800 MHz /8  = 100 MHz
		.CLKOUT0_PHASE      (0.000),
		.CLKOUT1_PHASE      (180.000),
		.CLKOUT2_PHASE      (0.000),
		.CLKOUT3_PHASE      (0.000),
		.CLKOUT4_PHASE      (0.000),
		.CLKOUT5_PHASE      (0.000),
		.CLKOUT0_DUTY_CYCLE (0.500),
		.CLKOUT1_DUTY_CYCLE (0.500),
		.CLKOUT2_DUTY_CYCLE (0.500),
		.CLKOUT3_DUTY_CYCLE (0.500),
		.CLKOUT4_DUTY_CYCLE (0.500),
		.CLKOUT5_DUTY_CYCLE (0.500),
		.COMPENSATION       ("SYSTEM_SYNCHRONOUS"),
		.REF_JITTER         (0.005000)
		)
	u_pll_adv
		(
		.CLKFBIN     (clkfbout_clkfbin),
		.CLKINSEL    (diff_input),
		.CLKIN1      (osc_clk_ibufgds),
		.CLKIN2      (osc_clk_ibufg),
		.DADDR       (5'b0),
		.DCLK        (1'b0),
		.DEN         (1'b0),
		.DI          (16'b0),
		.DWE         (1'b0),
		.REL         (1'b0),
		.RST         (RST),
		.CLKFBDCM    (),
		.CLKFBOUT    (clkfbout_clkfbin),
		.CLKOUTDCM0  (),
		.CLKOUTDCM1  (),
		.CLKOUTDCM2  (),
		.CLKOUTDCM3  (),
		.CLKOUTDCM4  (),
		.CLKOUTDCM5  (),
		.CLKOUT0     (MCBCLK_2X_0),
		.CLKOUT1     (MCBCLK_2X_180),
		.CLKOUT2     (clk25_bufg_in),
		.CLKOUT3     (calib_clk_bufg_in),
		.CLKOUT4     (clkout_bufg_in),
		.CLKOUT5     (proc_clk_bufg_in),
		.DO          (),
		.DRDY        (),
		.LOCKED      (MCBCLK_PLL_LOCK)
		);

//---------- 125 MHz TX clock ----------
// BUFG the DCM output
wire            xclk125_tx;
BUFG bufg125_tx(.I(xclk125_tx), .O(CLK125));
DCM_SP #(
  .CLKDV_DIVIDE(4.0),    // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                         //   7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
  .CLKFX_DIVIDE(8),            // Can be any integer from 1 to 32
  .CLKFX_MULTIPLY(5),          // Can be any integer from 2 to 32
  .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
  .CLKIN_PERIOD(5.0),          // Specify period of input clock
  .CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
  .CLK_FEEDBACK("1X"),         // Specify clock feedback of NONE, 1X or 2X
  .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                        //   an integer from 0 to 15
  .DLL_FREQUENCY_MODE("HIGH"),  // HIGH or LOW frequency mode for DLL
  .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
  .PHASE_SHIFT(0),              // Amount of fixed phase shift from -255 to 255
  .STARTUP_WAIT("FALSE")        // Delay configuration DONE until DCM LOCK, TRUE/FALSE
) DCM_SP_clk125tx (
  .CLK0(),            // 0 degree DCM CLK output
  .CLK180(),          // 180 degree DCM CLK output
  .CLK270(),          // 270 degree DCM CLK output
  .CLK2X(),           // 2X DCM CLK output
  .CLK2X180(),        // 2X, 180 degree DCM CLK out
  .CLK90(),           // 90 degree DCM CLK output
  .CLKDV(),           // Divided DCM CLK out (CLKDV_DIVIDE)
  .CLKFX(xclk125_tx), // DCM CLK synthesis out (M/D)
  .CLKFX180(),        // 180 degree CLK synthesis out
  .LOCKED(),          // DCM LOCK status output
  .PSDONE(),          // Dynamic phase adjust done output
  .STATUS(),          // 8-bit DCM status bits output
  .CLKFB(CLK125),     // DCM clock feedback
  .CLKIN(CLK_PLLOUT),     // Clock input (from IBUFG, BUFG or DCM)
  .PSCLK(1'b0),       // Dynamic phase adjust clock input
  .PSEN(1'b0),        // Dynamic phase adjust enable input
  .PSINCDEC(1'b0),    // Dynamic phase adjust increment/decrement
  .RST(!MCBCLK_PLL_LOCK) // DCM asynchronous reset input
);


//wire  phy_rxclk_ibufg;
//IBUFG ibufg125rx(.I(PHY_RXCLK), .O(CLK125_RX));


`endif // !`ifndef SIMULATE
endmodule
