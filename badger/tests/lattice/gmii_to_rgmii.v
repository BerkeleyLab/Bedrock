// see FPGA-TN-02035, Lattice ECP5 and ECP5-5G High-Speed I/O Interface
module gmii_to_rgmii #(
	parameter in_phase_tx_clk=0
) (
	// RGMII physical interface with PHY
	output [3:0] rgmii_txd, // to PHY
	output rgmii_tx_ctl,    // to PHY
	output rgmii_tx_clk,    // to PHY
	input [3:0] rgmii_rxd,  // from PHY
	input rgmii_rx_ctl,     // from PHY
	input rgmii_rx_clk,     // from PHY

	// GMII internal interface with MAC
	input gmii_tx_clk,      // from MAC
	input gmii_tx_clk90,    // from MAC
	input [7:0] gmii_txd,   // from MAC
	input gmii_tx_en,       // from MAC
	input gmii_tx_er,       // from MAC
	output [7:0] gmii_rxd,  // to MAC
	output gmii_rx_clk,     // to MAC
	output gmii_rx_dv,      // to MAC
	output gmii_rx_er,      // to MAC

	// not used
	input clk_div,
	input idelay_ce,
	input [4:0] idelay_value_in,
	output [4:0]     idelay_value_out_ctl,
	output [4:0]     idelay_value_out_data

);

// Tx instance array, see Figure 5.11
wire gmii_tx_ex = gmii_tx_en ^ gmii_tx_er;
wire [5:0] tx_d0 = {1'b1, gmii_tx_en, gmii_txd[3:0]};
wire [5:0] tx_d1 = {1'b0, gmii_tx_ex, gmii_txd[7:4]};
wire [5:0] tx_io;
ODDRX1F txd_obuf[5:0] (
	.SCLK(gmii_tx_clk),
	.RST(1'b0),
	.D0(tx_d0),
	.D1(tx_d1),
	.Q(tx_io));
assign rgmii_txd = tx_io[3:0];
assign rgmii_tx_ctl = tx_io[4];
assign rgmii_tx_clk = tx_io[5];

// Rx clock generation
wire rx_sclk = rgmii_rx_clk;
assign gmii_rx_clk = rx_sclk;

// Rx instance array, see Figure 5.1
wire [4:0] rx_io = {rgmii_rx_ctl, rgmii_rxd};
wire [4:0] rx_d0, rx_d1, rx_zz;
DELAYG #(.DEL_MODE("SCLK_CENTERED")) rxd_del[4:0] (
	.A(rx_io),
	.Z(rx_zz));
IDDRX1F rxd_ibuf[4:0] (
	.SCLK(rx_sclk),
	.RST(1'b0),
	.D(rx_zz),
	.Q0(rx_d0),
	.Q1(rx_d1));
assign gmii_rxd = {rx_d1[3:0], rx_d0[3:0]};
assign gmii_rx_er = rx_d1[4] ^ rx_d0[4];
assign gmii_rx_dv = rx_d0[4];

assign idelay_value_out_ctl = 0;
assign idelay_value_out_data = 0;

endmodule
