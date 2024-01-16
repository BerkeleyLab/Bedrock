// Ultra-stupid layer to define clock domains of signals coming in to marble_base
// See cdc_snitch.py
module marble_base_shell(
	// GMII Tx port
	input vgmii_tx_clk,
	output [7:0] vgmii_txd,
	output vgmii_tx_en,
	output vgmii_tx_er,

	// GMII Rx port
	input vgmii_rx_clk,
	input [7:0] vgmii_rxd,
	input vgmii_rx_er,
	input vgmii_rx_dv,

	// Auxiliary I/O and status
	input aux_clk,
	input clk62,
	input cfg_clk,
	output phy_rstn,
	input clk_locked,
	input si570,

	// SPI pins to on-board microcontroller; can give access to configuration
	input SCLK,
	input CSB,
	input MOSI,
	output MISO,
	output mmc_int,

	// SPI boot flash programming port
	output boot_clk,
	output boot_cs,
	output boot_mosi,
	input boot_miso,
	output cfg_d02,

	// One I2C bus; everything gatewayed through a TCA9548A
	// cdc_snitch still gets confused with inout ports like this
	inout  [3:0] twi_scl,
	inout  [3:0] twi_sda,
	inout  TWI_RST,
	input  TWI_INT,

	// White Rabbit compatible DAC subsystem controlling VCXOs
	output WR_DAC_SCLK,
	output WR_DAC_DIN,
	output WR_DAC1_SYNC,
	output WR_DAC2_SYNC,

	// UART to USB
	// The RxD and TxD directions are with respect
	// to the USB/UART chip, not the FPGA!
	// Note that the freq_demo feature doesn't actually use FPGA_TxD.
	// If you don't connect anything to FPGA_RxD, the synthesizer
	// will drop the whole freq_demo feature.
	output FPGA_RxD,
	input FPGA_TxD,

	// Digilent GPS
	input [3:0] GPS,

	// Placeholder for configuring external devices
	output [3:0] ext_config,

	// Simulation-only, please ignore in synthesis
	output in_use,

	// Local bus for an external application
	// Define clock domain
	output lb_clk,
	output [23:0] lb_addr,
	output lb_strobe,
	output lb_rd,
	output lb_write,
	output lb_rd_valid,
	// output [read_pipe_len:0] control_pipe_rd,
	output [31:0] lb_data_out,
	input [31:0] lb_data_in
);

(* magic_cdc *) reg [7:0] vgmii_rxd_r=0;
(* magic_cdc *) reg vgmii_rx_dv_r=0, vgmii_rx_er_r=0;
always @(posedge vgmii_rx_clk) begin
	vgmii_rxd_r <= vgmii_rxd;
	vgmii_rx_dv_r <= vgmii_rx_dv;
	vgmii_rx_er_r <= vgmii_rx_er;
end

(* magic_cdc *) reg [31:0] lb_data_in_r=0;
(* magic_cdc *) reg [3:0] GPS_r=0;
always @(posedge lb_clk) begin
	lb_data_in_r <= lb_data_in;
	GPS_r <= GPS;
end

marble_base i_mb(
	.vgmii_tx_clk(vgmii_tx_clk),
	.vgmii_txd(vgmii_txd),
	.vgmii_tx_en(vgmii_tx_en),
	.vgmii_tx_er(vgmii_tx_er),
	.vgmii_rx_clk(vgmii_rx_clk),
	.vgmii_rxd(vgmii_rxd_r),
	.vgmii_rx_er(vgmii_rx_er_r),
	.vgmii_rx_dv(vgmii_rx_dv_r),
	.aux_clk(aux_clk),
	.clk62(clk62),
	.cfg_clk(cfg_clk),
	.phy_rstn(phy_rstn),
	.clk_locked(clk_locked),
	.si570(si570),
	.SCLK(SCLK),
	.CSB(CSB),
	.MOSI(MOSI),
	.MISO(MISO),
	.mmc_int(mmc_int),
	.boot_clk(boot_clk),
	.boot_cs(boot_cs),
	.boot_mosi(boot_mosi),
	.boot_miso(boot_miso),
	.cfg_d02(cfg_d02),
	.twi_scl(twi_scl),
	.twi_sda(twi_sda),
	.TWI_RST(TWI_RST),
	.TWI_INT(TWI_INT),
	.WR_DAC_SCLK(WR_DAC_SCLK),
	.WR_DAC_DIN(WR_DAC_DIN),
	.WR_DAC1_SYNC(WR_DAC1_SYNC),
	.WR_DAC2_SYNC(WR_DAC2_SYNC),
	.FPGA_RxD(FPGA_RxD),
	.FPGA_TxD(FPGA_TxD),
	.GPS(GPS_r),
	.ext_config(ext_config),
	.in_use(in_use),
	.lb_clk(lb_clk),
	.lb_addr(lb_addr),
	.lb_strobe(lb_strobe),
	.lb_rd(lb_rd),
	.lb_write(lb_write),
	.lb_rd_valid(lb_rd_valid),
	.lb_data_out(lb_data_out),
	.lb_data_in(lb_data_in_r)
);

endmodule
