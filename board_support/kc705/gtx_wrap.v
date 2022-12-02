// GT transceiver wrapper tested on KC705 and BMB7
`timescale 1ns / 1ps

module gtx_wrap(
    input soft_reset,
    input gtrefclk_p,
    input gtrefclk_n,
    input drpclk_in,
    input [19:0] gt_txdata_in,
    output [19:0] gt_rxdata_out,
    // gt0
    input gt_txreset,
    input gt_rxreset,
    input gt_cpllreset,
    input gt_txusrrdy_in,
    input gt_rxusrrdy_in,
    input gt_rxn_in,
    input gt_rxp_in,
    output gt_txn_out,
    output gt_txp_out,
    output gt_rxresetdone,
    output gt_txresetdone,
    output gt_txfsm_resetdone_out,
    output gt_rxfsm_resetdone_out,
    output [2:0] gt_rxbufstatus,
    output [1:0] gt_txbufstatus,
    output gt_txusrclk_out,
    output gt_rxusrclk_out,
    output gt_cpll_locked
);


//----------------------------- GT Wrapper Wires ---------------------------
//________________________________________________________________________
//GT6   (X0Y1)
//------------ Receive Ports -RX Initialization and Reset Ports ------------
wire            gt0_rxresetdone_i;
//-------------------- Transmit Ports - TX Buffer Ports --------------------
wire    [1:0]   gt0_txbufstatus_i;
//----------- Transmit Ports - TX Initialization and Reset Ports -----------
wire            gt0_txresetdone_i;
//--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
wire            gt0_txoutclk_i;
wire            gt0_txoutclkfabric_i;
wire            gt0_txoutclkpcs_i;
//____________________________COMMON PORTS________________________________
//------------------------ Common Block - PLL Ports ------------------------
wire            gt0_cpll_lock_i;

//--------------------------------- User Clocks ---------------------------
wire gt0_rxusrclk_i;
wire gt0_txusrclk_i;

assign gt_txusrclk_out = gt0_txusrclk_i;
assign gt_rxusrclk_out = gt0_rxusrclk_i;
assign gt_rxresetdone = gt0_rxresetdone_i;
assign gt_txresetdone = gt0_txresetdone_i;
assign gt_cpll_locked = gt0_cpll_lock_i;

`ifndef SIMULATE

//--------------------------------- GTPE2_CHANNEL---------------------------
// 125MHz refclk, PLL freq = 0.125 * (n1 * n2)/m = 2.5GHz
// Line rate = 2.5*2/d =1.25Gb/s
// PLL Divider settings see UG482 Table 2-7 or UG476 table 2-11
// Configurable through gtwizard core settings.
// from gtwizard v3.6
gtwizard  gtwizard_i
(
	.soft_reset_tx_in(soft_reset), // input wire soft_reset_tx_in
	.soft_reset_rx_in(soft_reset), // input wire soft_reset_rx_in
	.dont_reset_on_data_error_in(1'b0), // input wire dont_reset_on_data_error_in
	.q2_clk0_gtrefclk_pad_n_in(gtrefclk_n), // input wire q2_clk0_gtrefclk_pad_n_in
	.q2_clk0_gtrefclk_pad_p_in(gtrefclk_p), // input wire q2_clk0_gtrefclk_pad_p_in
	.gt0_tx_fsm_reset_done_out(gt_txfsm_resetdone_out), // output wire gt0_tx_fsm_reset_done_out
	.gt0_rx_fsm_reset_done_out(gt_rxfsm_resetdone_out), // output wire gt0_rx_fsm_reset_done_out
	.gt0_data_valid_in(1'b1), // input wire gt0_data_valid_in

	.gt0_txusrclk_out(gt0_txusrclk_i), // output wire gt0_gt_txusrclk_out
	.gt0_txusrclk2_out(), // output wire gt0_txusrclk2_out
	.gt0_rxusrclk_out(gt0_rxusrclk_i), // output wire gt0_gt_rxusrclk_out
	.gt0_rxusrclk2_out(), // output wire gt0_rxusrclk2_out
//_________________________________________________________________________
//GT0  (X0Y0)
//____________________________CHANNEL PORTS________________________________
//------------------------------- CPLL Ports -------------------------------
	.gt0_cpllfbclklost_out          (), // output wire gt0_cpllfbclklost_out
	.gt0_cplllock_out               (gt0_cpll_lock_i), // output wire gt0_cplllock_out
	.gt0_cpllreset_in               (gt_cpllreset), // input wire gt0_cpllreset_in
//-------------------------- Channel - DRP Ports  --------------------------
	.gt0_drpaddr_in                 (9'b0), // input wire [8:0] gt0_drpaddr_in
	.gt0_drpdi_in                   (16'b0), // input wire [15:0] gt0_drpdi_in
	.gt0_drpdo_out                  (), // output wire [15:0] gt0_drpdo_out
	.gt0_drpen_in                   (1'b0), // input wire gt0_drpen_in
	.gt0_drprdy_out                 (), // output wire gt0_drprdy_out
	.gt0_drpwe_in                   (1'b0), // input wire gt0_drpwe_in
//------------------------- Digital Monitor Ports --------------------------
	.gt0_dmonitorout_out            (), // output wire [7:0] gt0_dmonitorout_out
//------------------- RX Initialization and Reset Ports --------------------
	.gt0_eyescanreset_in            (1'b0), // input wire gt0_eyescanreset_in
	.gt0_rxuserrdy_in               (gt_rxusrrdy_in), // input wire gt0_rxuserrdy_in
//------------------------ RX Margin Analysis Ports ------------------------
	.gt0_eyescandataerror_out       (), // output wire gt0_eyescandataerror_out
	.gt0_eyescantrigger_in          (1'b0), // input wire gt0_eyescantrigger_in
//---------------- Receive Ports - FPGA RX interface Ports -----------------
	.gt0_rxdata_out                 (gt_rxdata_out), // output wire [19:0] gt0_rxdata_out
//------------------------- Receive Ports - RX AFE -------------------------
	.gt0_gtxrxp_in                  (gt_rxp_in), // input wire gt0_gtxrxp_in
//---------------------- Receive Ports - RX AFE Ports ----------------------
	.gt0_gtxrxn_in                  (gt_rxn_in), // input wire gt0_gtxrxn_in
//------------------- Receive Ports - RX Equalizer Ports -------------------
	.gt0_rxdfelpmreset_in           (1'b0), // input wire gt0_rxdfelpmreset_in
	.gt0_rxmonitorout_out           (), // output wire [6:0] gt0_rxmonitorout_out
	.gt0_rxmonitorsel_in            (1'b0), // input wire [1:0] gt0_rxmonitorsel_in
//----------- Receive Ports - RX Initialization and Reset Ports ------------
	.gt0_gtrxreset_in               (gt_rxreset), // input wire gt0_gtrxreset_in
	.gt0_rxpmareset_in              (gt_rxreset), // input wire gt0_rxpmareset_in
//------------ Receive Ports -RX Initialization and Reset Ports ------------
	.gt0_rxresetdone_out            (gt0_rxresetdone_i), // output wire gt0_rxresetdone_out
//------------------- TX Initialization and Reset Ports --------------------
	.gt0_gttxreset_in               (gt_txreset), // input wire gt0_gttxreset_in
	.gt0_txuserrdy_in               (gt_txusrrdy_in), // input wire gt0_txuserrdy_in
//-------------------- Transmit Ports - TX Buffer Ports --------------------
	//.gt0_txbufstatus_out            (gt0_txbufstatus_i), // output wire [1:0] gt0_txbufstatus_out
//---------------- Transmit Ports - TX Data Path interface -----------------
	.gt0_txdata_in                  (gt_txdata_in), // input wire [19:0] gt0_txdata_in
//-------------- Transmit Ports - TX Driver and OOB signaling --------------
	.gt0_gtxtxn_out                 (gt_txn_out), // output wire gt0_gtxtxn_out
	.gt0_gtxtxp_out                 (gt_txp_out), // output wire gt0_gtxtxp_out
//--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
	.gt0_txoutclkfabric_out         (gt0_txoutclkfabric_i), // output wire gt0_txoutclkfabric_out
	.gt0_txoutclkpcs_out            (gt0_txoutclkpcs_i), // output wire gt0_txoutclkpcs_out
//----------- Transmit Ports - TX Initialization and Reset Ports -----------
	.gt0_txresetdone_out            (gt0_txresetdone_i), // output wire gt0_txresetdone_out

//____________________________COMMON PORTS________________________________
.gt0_qplloutclk_out(gt0_qplloutclk_out), // output wire gt0_qplloutclk_out
.gt0_qplloutrefclk_out(gt0_qplloutrefclk_out), // output wire gt0_qplloutrefclk_out
 .sysclk_in(drpclk_in) // input wire sysclk_in

);

`endif // `ifndef SIMULATE
endmodule
