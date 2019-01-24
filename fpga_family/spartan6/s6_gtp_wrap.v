// -------------------------------------------------------------------------------
// -- Title      : Deterministic Xilinx GTP wrapper - Spartan-6 top module
// -- Project    : llrf-eth
// -------------------------------------------------------------------------------
// -- File       : s6_gtp_wrap.v
// -- Author     : Qiang DU, Larry Doolittle
// -- Company    : LBL CBP
// -- Created    : 2012-04-11
// -- Last update: 2012-06-07
// -- Platform   : Xilinx Spartan-6T
// -- Standard   : Verilog
// -------------------------------------------------------------------------------
// -- Description: Dual channel wrapper for Xilinx Spartan-6 GTP adapted for
// -- deterministic delays at 1.25 Gbps.
// -------------------------------------------------------------------------------
// -------------------------------------------------------------------------------
// -- Revisions  :
// -- Date        Version  Author    Description
// -- 2012-04-11  0.1      Qiang Du  Initial Draft derived from gtp_wrap2.v, Xilinx
// --                                GTP Wizard v1.9, and wr_gtp_phy_spartan6
// --                                Only support Tile GTPA1_DUAL_X1Y0
// -------------------------------------------------------------------------------


`timescale 1ns / 1ps
// Bypass 8B/10B encoding and decoding, maximum compatibility with gtp_wrap2

module s6_gtp_wrap(
	input [9:0]  txdata0,
	output [9:0] rxdata0,
	output [6:0] rxstatus0,
	output       txstatus0,
	input [9:0]  txdata1,
	output [9:0] rxdata1,
	output [6:0] rxstatus1,
	output       txstatus1,
	output       tx_clk,
	output       rx_clk,
	output       tx_clk1,
	output       rx_clk1,
	input        gtp_reset_i,
	output       plllkdet, //  TILE0_PLLLKDET0_OUT
	output       plllkdet1, //  TILE0_PLLLKDET1_OUT
	output       resetdone,//  GTP0 reset done
        output       resetdone1,// GTP1 reset done
	// semantics-free ports, just have to carry the pins around
	input        refclk_p,
	input        refclk_n,
	input        rxn0,
	input        rxp0,
	output       txn0,
	output       txp0,
	input        rxn1,
	input        rxp1,
	output       txn1,
	output       txp1
	);

//------------------------------- PLL Ports --------------------------------
wire     plllkdet0_i;
wire     plllkdet1_i;
wire     resetdone0_i;
wire     resetdone1_i;

assign resetdone = resetdone0_i;
assign resetdone1 = resetdone1_i;
//---------------------Dedicated GTP Reference Clock Inputs ---------------
wire   gtp0_refclk_i;
`ifndef SIMULATE
// UG386 p.38, and Single GTPA1_DUAL Tile Clocked Externally  p.44, Fig 2-4
IBUFDS #(.DIFF_TERM("TRUE")) gtp0_refclk_ibufds_i (
      .O(gtp0_refclk_i),
      .I(refclk_p),
      .IB(refclk_n)
      );

//--------------------------------- User Clocks ---------------------------
wire    txusrclk0_i;
wire    txusrclk1_i;
wire    rxusrclk0_i;
wire    rxusrclk1_i;
wire    rxrecclk0_i;
wire    rxrecclk1_i;
wire    gtpclkout0_0_to_bufg_i;
wire    gtpclkout0_1_to_bufg_i;
wire    gtpclkout1_1_to_bufg_i;
wire    gtpclkout1_0_to_bufg_i;
wire [1:0]     gtpclkout0_i;
wire [1:0]     gtpclkout1_i;
wire     refclkout0_i;
wire     refclkout1_i;

assign rx_clk = rxrecclk0_i;
assign tx_clk = txusrclk0_i;
assign rx_clk1 = rxrecclk1_i;
assign tx_clk1 = txusrclk1_i;

// Using GTPCLKOUT to Drive the GTP TX
// UG386 p.73, and Figure 3-5: GTPCLKOUT[0] Driving TXUSRCLK and TXUSRCLK2
// REFCLKOUT0/1 is described as reserved bit and should use GTPCLKOUT(0/1)[0] instead
BUFIO2 # (
    .DIVIDE                         (1),
    .DIVIDE_BYPASS                  ("TRUE")
    ) gtpclkout0_0_bufg0_bufio2_i (
    .I                              (gtpclkout0_i[0]),
    .DIVCLK                         (gtpclkout0_0_to_bufg_i)
);

BUFG gtpclkout0_0_bufg0_i (
    .I                              (gtpclkout0_0_to_bufg_i),
    .O                              (txusrclk0_i)
);

BUFIO2 # (
    .DIVIDE                         (1),
    .DIVIDE_BYPASS                  ("TRUE")
    ) gtpclkout1_0_bufg0_bufio2_i (
    .I                              (gtpclkout1_i[0]),
    .DIVCLK                         (gtpclkout1_0_to_bufg_i)
);

BUFG gtpclkout1_0_bufg0_i (
    .I                              (gtpclkout1_0_to_bufg_i),
    .O                              (txusrclk1_i)
);

// Use the recovered clock for the Rx subsystem

BUFIO2 # (
    .DIVIDE                         (1),
    .DIVIDE_BYPASS                  ("TRUE")
    ) gtpclkout0_1_bufg0_bufio2_i (
    .I                              (gtpclkout0_i[1]),
    .DIVCLK                         (gtpclkout0_1_to_bufg_i)
);

BUFG gtpclkout0_1_bufg0_i (
    .I                              (gtpclkout0_1_to_bufg_i),
    .O                              (rxusrclk0_i)
);

BUFIO2 # (
    .DIVIDE                         (1),
    .DIVIDE_BYPASS                  ("TRUE")
    ) gtpclkout1_1_bufg2_bufio2_i (
    .I                              (gtpclkout1_i[1]),
    .DIVCLK                         (gtpclkout1_1_to_bufg_i)
);

BUFG gtpclkout1_1_bufg2_i (
    .I                              (gtpclkout1_1_to_bufg_i),
    .O                              (rxusrclk1_i)
);

wire       rxbufreset0=0;
wire       rxbufreset1=0;

//-------------------------- Tx/Rx status --------------------------
// Assemble the 7-bit Rx status word
// Assignments for 10 bit datapath
// assign rxdata0_out_i = {rxdisperr0_i[0],rxcharisk0_i[0],rxdata0_i[7:0]};
wire       rxbyteisaligned0,  rxbyteisaligned1;
wire [1:0] rxlossofsync0,     rxlossofsync1; //not hooked up;
//--------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
wire [2:0]   rxbufstatus0_i;
wire [2:0]   rxbufstatus1_i;

assign rxstatus0 = {2'b0, rxlossofsync0[1],
                    rxbyteisaligned0, rxbufstatus0_i};
assign rxstatus1 = {2'b0, rxlossofsync1[1],
                    rxbyteisaligned1, rxbufstatus1_i};

// Only one bit of Tx status for now
//wire       txrundisp0, txrundisp1;
wire [1:0] txbufstatus0_i;
wire [1:0] txbufstatus1_i;
assign txstatus0 = txbufstatus0_i[1];
assign txstatus1 = txbufstatus1_i[1];

// Instantiate the GTP_DUAL directly.
// Attributes generated from coregen Wizard.

// Wire all PLLLKDET signals to the top level as output port
assign plllkdet = plllkdet0_i;
assign plllkdet1 = plllkdet1_i;

GTPA1_DUAL #(
`include "s6_gtp_params.vh"
             .CLK25_DIVIDER_0                (5),
             .CLK25_DIVIDER_1                (5),
             .PLL_DIVSEL_FB_0                (2),
             .PLL_DIVSEL_FB_1                (2),
             .PLL_DIVSEL_REF_0               (1),
             .PLL_DIVSEL_REF_1               (1)
) foo (
        //---------------------- Loopback and Powerdown Ports ----------------------
	.RXPOWERDOWN0         (2'b0),
	.RXPOWERDOWN1         (2'b0),
	.TXPOWERDOWN0         (2'b0),
	.TXPOWERDOWN1         (2'b0),
	//------------------------------- PLL Ports --------------------------------
	.CLK00                (gtp0_refclk_i),
	.CLK01                (gtp0_refclk_i),
	.GTPRESET0            (gtp_reset_i),
	.GTPRESET1            (gtp_reset_i),
	.PLLLKDET0            (plllkdet0_i),
        .PLLLKDET1            (plllkdet1_i),
        .INTDATAWIDTH0        (1'b1), // internal data with 8 bit
        .INTDATAWIDTH1        (1'b1), // internal data with 8 bit
        .PLLLKDETEN0          (1'b1), // enable PLLLKDET0
        .PLLLKDETEN1          (1'b1), // enable PLLLKDET1
	.REFCLKOUT0           (refclkout0_i),
	.REFCLKOUT1           (refclkout1_i),
	.RESETDONE0           (resetdone0_i),
	.RESETDONE1           (resetdone1_i),
        .REFCLKPWRDNB0        (1'b1), // shut down IBUGDS if no ref
        .REFCLKPWRDNB1        (1'b1), // shut down IBUGDS if no ref
        .REFSELDYPLL0         (2'b0), // select CLK00 as ref for PLL0
        .REFSELDYPLL1         (2'b0), // select CLK01 as ref for PLL1
	//------------- Receive Ports - Comma Detection and Alignment --------------
	.RXBYTEISALIGNED0      (rxbyteisaligned0),
	.RXBYTEISALIGNED1      (rxbyteisaligned1),
        .RXCOMMADETUSE0        (1'b1), // enable RX comma det and alignment
        .RXCOMMADETUSE1        (1'b1),
	.RXENMCOMMAALIGN0      (1'b1), // Aligns the byte boundary when comma minus is detected
	.RXENMCOMMAALIGN1      (1'b1),
	.RXENPCOMMAALIGN0      (1'b1), // Aligns the byte boundary when comma plus  is detected
	.RXENPCOMMAALIGN1      (1'b1),
	//-------------------- Receive Ports - Channel Bonding ---------------------
	.RXCHBONDI             (2'b0), // disable channel bonding
	//----------------- Receive Ports - RX Data Path interface -----------------
	// Table 4-38: FPGA Interface RX Ports
	// Table 4-26: RX Decoder Ports
	// (and see Figure 4-35 since we bypass 8B/10B decoding)
	.RXDATAWIDTH0          (2'b00),
	.RXDEC8B10BUSE0        (1'b0),
	.RXDATA0               (rxdata0[7:0]),
	.RXCHARISK0            (rxdata0[8]),
	.RXDISPERR0            (rxdata0[9]),
	.RXDATAWIDTH1          (2'b00),
	.RXDEC8B10BUSE1        (1'b0),
	.RXDATA1               (rxdata1[7:0]),
	.RXCHARISK1            (rxdata1[8]),
	.RXDISPERR1            (rxdata1[9]),
	.RXRECCLK0             (rxrecclk0_i),
	.RXRECCLK1             (rxrecclk1_i),
	.RXUSRCLK0             (rxusrclk0_i),
	.RXUSRCLK1             (rxusrclk1_i),
	.RXUSRCLK20            (rxusrclk0_i),
	.RXUSRCLK21            (rxusrclk1_i),
	//------------- Physical Rx pins -------------------------------------------
        .RXEQMIX0              (2'b11), // 8.4dB gain of RX Equalizaiton Ctrl
        .RXEQMIX1              (2'b11),
	.RXN0                  (rxn0),
	.RXN1                  (rxn1),
	.RXP0                  (rxp0),
	.RXP1                  (rxp1),
	//--------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
	.RXBUFSTATUS0          (rxbufstatus0_i),
	.RXBUFSTATUS1          (rxbufstatus1_i),
	//-------------------------- TX/RX Datapath Ports --------------------------
	// Table 4-28
        .GTPCLKFBSEL0EAST      (2'b10),
        .GTPCLKFBSEL0WEST      (2'b00),
        .GTPCLKFBSEL1EAST      (2'b11),
        .GTPCLKFBSEL1WEST      (2'b01),
	//------------- Transmit Ports - TX Buffer and Phase Alignment -------------
	.TXBUFSTATUS0          (txbufstatus0_i),
	.TXBUFSTATUS1          (txbufstatus1_i),
	.TXDATAWIDTH0	       (2'b00),
	.TXDATAWIDTH1	       (2'b00),
	// Table 3-1: FPGA TX Interface Ports
	.GTPCLKOUT0            (gtpclkout0_i),
	.GTPCLKOUT1            (gtpclkout1_i),
	.TXDATA0               (txdata0[7:0]),
	.TXCHARDISPVAL0        (txdata0[8]),
	.TXCHARDISPMODE0       (txdata0[9]),
	.TXDATA1               (txdata1[7:0]),
	.TXCHARDISPVAL1        (txdata1[8]),
	.TXCHARDISPMODE1       (txdata1[9]),
	.TXOUTCLK0             (txoutclk0_i),
	.TXOUTCLK1             (txoutclk1_i),
	.TXUSRCLK0             (txusrclk0_i),
	.TXUSRCLK1             (txusrclk1_i),
	.TXUSRCLK20            (txusrclk0_i),
	.TXUSRCLK21            (txusrclk1_i),
	//------------- Physical Tx pins -------------------------------------------
	.TXN0                  (txn0),
	.TXN1                  (txn1),
	.TXP0                  (txp0),
	.TXP1                  (txp1)
);
`endif

// Found in s6_gtpwizard_tile.v but not UG386:
//  USRCODEERR0   USRCODEERR1
//  GATERXELECIDLE0   GATERXELECIDLE1
//  RCALINEAST0   RCALINEAST1
endmodule
