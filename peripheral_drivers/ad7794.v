module ad7794 #(parameter ADDR_WIDTH=8,parameter DATA_WIDTH=24,parameter SPIMODE="passthrough") (
	output                  CLK,
	output                  CS,
	output                  DIN,
	input                   DOUT_RDY,
	output                  SCLK,
	input                   clkin,
	input                   spi_start,
	output                  spi_busy,  // For handshaking; can be ignored
	input [ADDR_WIDTH-1:0]  spi_addr,
	input                   spi_read,
	input [DATA_WIDTH-1:0]  spi_data,
	output [ADDR_WIDTH-1:0] sdo_addr,
	output [DATA_WIDTH-1:0] spi_rdbk,
	output                  spi_ready,
	output                  sdio_as_sdo,
	input                   sclk_in,
	input                   mosi_in,
	input                   ss_in,
	output                  miso_out,
	input                   spi_ssb_in,
	output                  spi_ssb_out,
	input                   adcclk
);
// pin       CS is      IO_L1P_T0_32 bank  32 bus_digitizer_U18[2]       AE17
// pin      CLK is      IO_L5P_T0_32 bank  32 bus_digitizer_U18[0]       AF19
// pin      DIN is     IO_L23N_T3_32 bank  32 bus_digitizer_U18[3]        V19
// pin     SCLK is     IO_L17N_T2_34 bank  34 bus_digitizer_U18[4]         Y5
// pin DOUT/RDY is      IO_L1N_T0_32 bank  32 bus_digitizer_U18[1]       AF17

wire sclk_7794, mosi_7794;
wire miso_7794, ss_7794;
generate
if (SPIMODE=="passthrough") begin: passthrough
	assign SCLK = sclk_in;
	assign DIN = mosi_in;
	assign CS = ss_in;
	assign miso_out = DOUT_RDY;
	assign CLK = adcclk;
end
else if (SPIMODE=="chain") begin: no_passthrough
	assign SCLK = spi_ssb_in ? sclk_7794 : sclk_in;
	assign DIN = spi_ssb_in ? mosi_7794 : mosi_in;
	assign CS = ss_7794;
	assign miso_7794 = DOUT_RDY;
	assign CLK = adcclk;
end
else if (SPIMODE=="standalone") begin
	assign SCLK = sclk_7794;
	assign DIN = mosi_7794;
	assign CS = ss_7794;
	assign miso_7794 = DOUT_RDY;
	assign CLK = adcclk;
end
endgenerate

wire start_7794 = spi_start;
assign spi_ssb_out = spi_ssb_in & CS;
spi_master #(.TSCKHALF(16), .ADDR_WIDTH(8), .DATA_WIDTH(24), .SCK_RISING_SHIFT(0))
ad7794_spi (
	.cs(ss_7794), .sck(sclk_7794), .sdi(mosi_7794), .sdo(miso_7794),
	.clk(clkin), .spi_start(start_7794), .spi_busy(spi_busy), .spi_read(spi_read),
	.spi_addr(spi_addr), .spi_data(spi_data), .sdo_addr(sdo_addr),
	.spi_rdbk(spi_rdbk), .spi_ready(spi_ready), .sdio_as_sdo(sdio_as_sdo)
);

endmodule
