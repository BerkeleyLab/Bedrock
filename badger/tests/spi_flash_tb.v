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
client_sub #(.n_lat(n_lat), .sim_length(2000)) net(.clk(clk), .len_c(len_c), .idata(idata),
	.raw_l(raw_l), .raw_s(raw_s), .odata(odata));

// DUT
wire spi_clk, spi_cs, spi_mosi, spi_miso;
spi_flash #(.n_lat(n_lat)) dut(.clk(clk),
	.len_c(len_c), .idata(idata), .raw_l(raw_l), .raw_s(raw_s),
	.odata(odata),
	.spi_clk(spi_clk), .spi_cs(spi_cs),
	.spi_mosi(spi_mosi), .spi_miso(spi_miso)
);

// SPI Flash memory
flash flash(.clk(spi_clk), .cs(spi_cs),
	.mosi(spi_mosi), .miso(spi_miso));

endmodule

// Pathetic emulation of external SPI Flash chip
// Just provide a placeholder message for every SPI command.
// Cribbed from scaffold_tb.v
module flash(
	input clk,
	input cs,
	input mosi,
	output miso
);
reg [63:0] sr;
always @(negedge cs) sr<=64'h7172737475767778;
always @(posedge clk) sr<={sr[62:0],1'bx};

// Receive bits from master
reg [79:0] rx_reg=0;
always @(negedge cs) rx_reg <= 0;
always @(posedge clk) if (~cs) rx_reg <= {rx_reg[78:0],mosi};
always @(posedge cs) $display("Flash received %x from SPI master",rx_reg);
reg dout;
always @(negedge clk or negedge cs) begin
	dout=1'bx;
	#7;
	dout=sr[63];
end
assign miso = cs ? 1'bx : dout;  // or maybe 1'bx when not addressed?

endmodule
