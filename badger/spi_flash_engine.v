`timescale 1ns / 1ns
module spi_flash_engine(
	input clk,
	// 4-wire to e.g., Winbond W25X16
	output spi_clk,
	output spi_cs,
	output spi_mosi,
	input spi_miso,
	// port to read packet memory
	input pack_read_ready,
	input [8:0] input_packet_len,
	output pack_read_strobe,
	input [7:0] pack_data_in,
	output pack_read_done,   // marks memory as empty
	// port to write packet memory
	output pack_write,   // high for whole transaction
	input pack_write_ack,  // see below
	output pack_write_strobe,  // single-cycle for each data byte
	output [7:0] pack_data_out
);

// packet write, and indeed the whole engine, will stall until
// pack_write_ack is received.  The ack will often happen immediately,
// but can be substantially delayed if the output packet buffer is busy
// handling a microcontroller output packet.

// spi_clk is rated to 50 MHz, but we have no real reason to push this.
// Most of the clock time will be spent after the write or erase SPI
// transactions, waiting for the busy flag to go away.
// Use 32 ns high / 32 ns low, 15.6 MBit/s.

// Abstract spi_mosi is valid 4 cycles before and 4 cycles after the rising
// edge of spi_clk.  The real W25Xxx requires the real data pin valid 2ns
// before and 5ns after the rising edge of the real clock pin.

// The real X25Xxx specifies its data is output 0ns to 7ns after the falling
// edge of its clock.  This module samples spi_miso on the rising edge
// of spi_clk.

// Encode length byte as
//   256 4 2 1
// Allows likely lengths 1, 2, 4, 6, 260, and 261.
// Leaves additional control bits to possibly encode a special
// "read status register repeatedly until done" mode.

reg running=0;
reg [8:0] block_len=0;
reg [8:0] bytes_remaining=0;
reg word=0;
reg icap_en=0;
always @(posedge clk) begin
	if (pack_write_ack & word & ~running) begin
		running<=1;
		bytes_remaining<=input_packet_len;
	end else begin
		if (~pack_read_ready | (bytes_remaining==0)) running<=0;
	end
	if (running & word2) begin
		block_len <= (|block_len) ? (block_len-1) : {pack_data_in[3],5'b0,pack_data_in[2:0]};
		if (~(|block_len)) icap_en <= pack_data_in[7];
		bytes_remaining <= bytes_remaining-1;
	end
	if (running & word3 & ~(|block_len)) icap_en <= 0;
	if (!running) icap_en <= 0;
end

reg [6:0] subtick=0;
reg [7:0] sr=0;
reg tick=0, tick2=0, tick3=0, tick4=0, word2=0, word3=0, word4=0;
reg spi_clk_r=0, spi_clk_rr=0, spi_miso_r=0, spi_cs_pre=0, spi_cs_r=0, in_bit=0;
wire [7:0] sr_next = {sr[6:0], in_bit};
always @(posedge clk) begin
	subtick <= subtick+1;
	tick <= subtick[3:0]==13;
	tick2 <= tick;
	tick3 <= tick2;
	tick4 <= tick3;
	word <= subtick==125;
	word2 <= word;
	word3 <= word2;
	word4 <= word3;
	spi_clk_r <= subtick[3]&running&~icap_en&(|block_len);
	spi_clk_rr <= spi_clk_r;
	spi_miso_r <= spi_miso;  // IOB
	if (subtick[3:0]==11) in_bit <= spi_cs_r ? spi_miso_r : 1'b0;
	spi_cs_pre <= running&~icap_en&(|block_len)&(|bytes_remaining);
	spi_cs_r <= spi_cs_pre;
	if (tick4 & running) sr <= (word4&(|block_len)) ? pack_data_in : sr_next;
end

assign spi_clk=spi_clk_rr;
assign spi_cs=~spi_cs_r;
assign spi_mosi=sr[7]&spi_cs_r;

// Optional support for ICAP_SPARTAN6
// Keep the same basic timing engine as SPI.
// Bit-reverse bytes per UG380 Table 2-5
wire [7:0] pack_data_in_rev={
	pack_data_in[0], pack_data_in[1], pack_data_in[2], pack_data_in[3],
	pack_data_in[4], pack_data_in[5], pack_data_in[6], pack_data_in[7]};
reg odd=0, icap_clk=0, icap_we=0, icap_en2=0;
reg [7:0] icap_upper_data=0;
always @(posedge clk) begin
	if (word2) icap_en2 <= icap_en;
	if (word3) icap_we <= icap_en2 & odd;
	if (word3) icap_upper_data <= pack_data_in_rev;
	if (word & icap_en) odd <= ~odd;
	icap_clk <= subtick[6] & odd & ~word2;
end
wire [15:0] icap_wdata = {icap_upper_data,pack_data_in_rev};
wire [15:0] icap_result;
wire icap_busy;

//`define SP60X 1
`ifdef SP60X
// 16-bit I port (for writing) and O port (for reading)
ICAP_SPARTAN6 intern(.CLK(icap_clk),
	.CE(~icap_en), // icap_en is active high, CE "pin" is active low
	.WRITE(1'b0), // funny name for a pin where "0" means write
	.I(icap_wdata),
	.O(icap_result), .BUSY(icap_busy));
`else
assign icap_result=0;
assign icap_busy=0;
`endif
wire [7:0] icap_result_byte={7'b1010000,icap_busy};  // XXX useless for actually reading data

assign pack_read_strobe=word2&running;
assign pack_read_done=running&(bytes_remaining==0);

assign pack_write=pack_read_ready;
assign pack_write_strobe=word&running;
assign pack_data_out = icap_en ? icap_result_byte : sr_next;

endmodule
