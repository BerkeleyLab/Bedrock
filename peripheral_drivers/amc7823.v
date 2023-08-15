module amc7823 #(
	parameter ADDR_WIDTH=16,
	parameter DATA_WIDTH=16,
	parameter SPIMODE="passthrough"
) (
	output                  ss,
	input                   miso,
	output                  mosi,
	output                  sclk,
	input                   clk,
	input                   spi_start,
	output                  spi_busy,  // For handshaking; can be ignored
	input  [ADDR_WIDTH-1:0] spi_addr,
	input                   spi_read,
	input  [DATA_WIDTH-1:0] spi_data,
	output [ADDR_WIDTH-1:0] sdo_addr,
	output [DATA_WIDTH-1:0] spi_rdbk,
	output                  spi_ready,
	output                  sdio_as_sdo,
	input                   sclk_in,
	input                   mosi_in,
	output                  miso_out,
	input                   ss_in,
	input                   spi_ssb_in,
	output                  spi_ssb_out
);
// pin    ss is        IO_L18N_T2_32 bank  32 bus_digitizer_U15[2]       AB20
// pin  miso is        IO_L18P_T2_32 bank  32 bus_digitizer_U15[1]       AB19
// pin  mosi is        IO_L23N_T3_32 bank  32 bus_digitizer_U18[3]        V19
// pin  sclk is        IO_L17N_T2_34 bank  34 bus_digitizer_U18[4]         Y5

wire sclk_7823, mosi_7823;
wire miso_7823, ss_7823;
generate
if (SPIMODE=="passthrough") begin: passthrough
	assign sclk = sclk_in;
	assign mosi = mosi_in;
	assign ss = ss_in;
	assign miso_out = miso;
end
else if (SPIMODE=="chain") begin: no_passthrough
	assign sclk = spi_ssb_in ? sclk_7823 : sclk_in;
	assign mosi = spi_ssb_in ? mosi_7823 : mosi_in;
	assign ss = ss_7823;
	assign miso_7823 = miso;
end
else if (SPIMODE=="standalone") begin
	assign sclk = sclk_7823;
	assign mosi = mosi_7823;
	assign ss = ss_7823;
	assign miso_7823 = miso;
end
endgenerate
wire start_7823 = spi_start;
assign spi_ssb_out= spi_ssb_in & ss;
spi_master #(.TSCKHALF(16), .ADDR_WIDTH(16), .DATA_WIDTH(16), .SCK_RISING_SHIFT(1))
amc7823_spi (
	.cs(ss_7823), .sck(sclk_7823), .sdi(mosi_7823), .sdo(miso_7823),
	.clk(clk), .spi_start(start_7823), .spi_busy(spi_busy), .spi_read(spi_read),
	.spi_addr(spi_addr), .spi_data(spi_data), .sdo_addr(sdo_addr),
	.spi_rdbk(spi_rdbk), .spi_ready(spi_ready), .sdio_as_sdo(sdio_as_sdo)
);

endmodule
