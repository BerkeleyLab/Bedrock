// Test bench for the spi_flash world client,
// See hello_tb.v for more comments.
//
`timescale 1ns / 1ns
module spi_flash_tb;

parameter n_lat=12;

initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("spi_flash.vcd");
		$dumpvars(5, spi_flash_tb);
	end
end

// Gateway to UDP, client interface test generator
wire [10:0] len_c;
wire [7:0] idata, odata;
wire clk, raw_l, raw_s;
wire busy;
client_sub #(.n_lat(n_lat), .sim_length(35000), .msg_len(265)) net(
	.clk(clk), .len_c(len_c), .idata(idata),
	.raw_l(raw_l), .raw_s(raw_s), .odata(odata), .thinking(busy));

// DUT
wire spi_clk, spi_cs, spi_mosi, spi_miso;
spi_flash #(.n_lat(n_lat)) dut(.clk(clk),
	.len_c(len_c), .idata(idata), .raw_l(raw_l), .raw_s(raw_s),
	.odata(odata),
	.spi_clk(spi_clk), .spi_cs(spi_cs),
	.spi_mosi(spi_mosi), .spi_miso(spi_miso),
	.busy(busy)
);

// SPI Flash memory
spiflash flash(.clk(spi_clk), .csb(spi_cs),
	.io0(spi_mosi), // MOSI
	.io1(spi_miso)  // MISO
);

endmodule
