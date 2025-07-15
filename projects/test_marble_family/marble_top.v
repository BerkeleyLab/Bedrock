// Top level Marble-Mini and Marble v2 test build
// Mostly cut-and-paste from rgmii_hw_test.v

`include "marble_features_defs.vh"

module marble_top(
	input GTPREFCLK_P,
	input GTPREFCLK_N,
`ifdef MARBLE_V2
	input DDR_REF_CLK_P,
	input DDR_REF_CLK_N,
`endif
	input SYSCLK_P,

	// SI570 clock inputs
	`ifdef USE_SI570
	input GTREFCLK_P,
	input GTREFCLK_N,
	`endif

	// RGMII Tx port
	output [3:0] RGMII_TXD,
	output RGMII_TX_CTRL,
	output RGMII_TX_CLK,

	// RGMII Rx port
	input [3:0] RGMII_RXD,
	input RGMII_RX_CTRL,
	input RGMII_RX_CLK,

	// Reset command to PHY
	output PHY_RSTN,

	// SPI pins connected to microcontroller
	input SCLK,
	input CSB,
	input MOSI,
	output MISO,
	output MMC_INT,

	// SPI boot flash programming port
	// BOOT_CCLK treated specially in 7-series
	output BOOT_CS_B,
	input  BOOT_MISO,
	output BOOT_MOSI,
	output CFG_D02,  // hope R209 is DNF

	// One I2C bus, with everything gatewayed through a TCA9548
	inout  TWI_SCL,
	inout  TWI_SDA,
	inout  TWI_RST,
	input  TWI_INT,

	// White Rabbit DAC
	output WR_DAC_SCLK,
	output WR_DAC_DIN,
	output WR_DAC1_SYNC,
	output WR_DAC2_SYNC,

	// UART to USB
	// The RxD and TxD directions are with respect
	// to the USB/UART chip, not the FPGA!
	output FPGA_RxD,
	input FPGA_TxD,

	output VCXO_EN,

	// FMC stuff
	inout [33:0] FMC1_LA_P,
	inout [33:0] FMC1_LA_N,
	inout [33:0] FMC2_LA_P,
	inout [33:0] FMC2_LA_N,
`ifdef MARBLE_V2
	inout [1:0] FMC1_CK_P,
	inout [1:0] FMC1_CK_N,
	inout [1:0] FMC2_CK_P,
	inout [1:0] FMC2_CK_N,
	inout [23:0] FMC2_HA_P,
	inout [23:0] FMC2_HA_N,
`endif
	// output ZEST_PWR_EN,

`ifdef MARBLE_V2
	// Special for LTM4673 synchronization
	output [2:0] LTM_CLKIN,
`endif

`ifdef MARBLE_MINI
	// J15 TMDS 0, 1, 2, CLK
	output [3:0] TMDS_P,
	output [3:0] TMDS_N,
`endif

	// Directly attached LEDs
	output LD16,
	output LD17,

	// Physical Pmod, may be used as LEDs
	output [7:0] Pmod1,  // feel free to change to inout, if you attach to something other than LEDs
	input [7:0] Pmod2
);

`include "marble_features_params.vh"

// Local bus provided by marble_base; currently unused
wire lb_clk, lb_strobe, lb_rd, lb_write, lb_rd_valid;
wire [23:0] lb_addr;
wire [31:0] lb_data_out;
wire [31:0] lb_din;
assign lb_din = 32'hfaceface;

`ifndef MARBLE_V2
wire [1:0] FMC1_CK_P;
wire [1:0] FMC1_CK_N;
wire [1:0] FMC2_CK_P;
wire [1:0] FMC2_CK_N;
wire [23:0] FMC2_HA_P;
wire [23:0] FMC2_HA_N;
`endif

`include "marble_mid.vh"

endmodule
