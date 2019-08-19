// Pathetic emulation of external SPI Flash chip
// Just provide a placeholder message for every SPI command.
// Cribbed from scaffold_tb.v
module spiflash(
	input clk,
	input csb,
	inout io0,  // MOSI
	inout io1   // MISO
);
reg [63:0] sr;
always @(negedge csb) sr<=64'h7172737475767778;
always @(posedge clk) sr<={sr[62:0],1'bx};

// Receive bits from master
reg [79:0] rx_reg=0;
always @(negedge csb) rx_reg <= 0;
always @(posedge clk) if (~csb) rx_reg <= {rx_reg[78:0], io0};
always @(posedge csb) $display("Flash received %x from SPI master",rx_reg);
reg dout;
always @(negedge clk or negedge csb) begin
	dout=1'bx;
	#7;
	dout=sr[63];
end
assign io1 = csb ? 1'bx : dout;  // or maybe 1'bz when not addressed?

endmodule
