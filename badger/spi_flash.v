// Mechanism to reprogram boot flash
module spi_flash(
	input clk,
	// client interface with RTEFI, see clients.eps
	input [10:0] len_c,
	input [7:0] idata,
	input raw_l,
	input raw_s,
	output [7:0] odata,
	// 4-wire to e.g., Winbond W25X16
	output spi_clk,
	output spi_cs,
	output spi_mosi,
	input spi_miso
);

parameter n_lat = 8;  // latency of client pipeline

// Try really hard to be non-fancy here, just the obvious way of
// gatewaying the previoiusly functioning spi_flash_engine into
// the RTEFI scheme.

// Longer term it would be nice if this could be re-written to
// allow more resource sharing, say between Rx and Tx buffers,
// and code sharing with other buffered clients, like the SPI
// slave gateway to a microcontroller, as was done in PSPEPS.

// This module cries out to be a customer of an authentication
// mechanism, whenever that becomes available.

parameter aw=9;  // nominal/minimal 512 x 8
reg [7:0] rx_mem[0:1<<aw-1];
reg [7:0] tx_mem[0:1<<aw-1];

reg pack_read_ready=0;
reg [8:0] rx_packet_len;
wire pack_read_strobe;
reg [7:0] pack_data_rx=0;

wire pack_read_done;
wire pack_write;
wire pack_write_ack=1;
wire pack_write_strobe;
wire [7:0] pack_data_tx;

spi_flash_engine engine(
	.clk(clk),
	.spi_clk(spi_clk),
	.spi_cs(spi_cs),
	.spi_mosi(spi_mosi),
	.spi_miso(spi_miso),
	//
	.pack_read_ready(pack_read_ready),
	.input_packet_len(rx_packet_len),
	.pack_read_strobe(pack_read_strobe),
	.pack_data_in(pack_data_rx),
	.pack_read_done(pack_read_done),
	//
	.pack_write(pack_write),
	.pack_write_ack(pack_write_ack),
	.pack_write_strobe(pack_write_strobe),
	.pack_data_out(pack_data_tx)
);

// Adapt the RTEFI control lines into what we need;
// shared between Rx writer and Tx reader.
reg [1:0] raw_sr=0;
reg [aw-1:0] eth_point=0;
always @(posedge clk) begin
	raw_sr <= {raw_sr[0:0], raw_s};
        eth_point <= raw_sr[1] ? eth_point+1 : 0;
end

// Logic for writing Rx memory
// Note the decoding of the first byte as a packet-global op-code:
//  0x52   write buffer
// The write command will fail if the buffer is not empty, and that
// failure  gets reported in the status message, below, right?
reg write_pack_flag=0;
always @(posedge clk) begin
	if (raw_s & ~raw_sr[0]) write_pack_flag <= idata == 8'h52;
	if (raw_s & raw_sr[1] & write_pack_flag) rx_mem[eth_point] <= idata;
	if (raw_sr[0] & ~raw_s & write_pack_flag) pack_read_ready <= 1;
	if (raw_sr[0] & ~raw_s & write_pack_flag) rx_packet_len <= eth_point;
	if (pack_read_done) pack_read_ready <= 0;
end

// Logic for reading Rx memory
reg [aw-1:0] rx_rpoint=0;
always @(posedge clk) begin
	if (pack_read_done) rx_rpoint <= 0;
	if (pack_read_strobe) rx_rpoint <= rx_rpoint+1;
	pack_data_rx <= rx_mem[rx_rpoint];
end

// Logic for writing Tx memory
reg [aw-1:0] tx_wpoint=0;
always @(posedge clk) begin
	if (pack_write_strobe) begin
		tx_mem[tx_wpoint] <= pack_data_tx;
		tx_wpoint <= tx_wpoint+1;
	end
	if (~pack_write) tx_wpoint <= 0;
end

// Logic for reading Tx memory
// len_c counts down to 9, but we need something that counts up from 0
wire [7:0] tx_status = {write_pack_flag, pack_read_done};  // ???
reg [7:0] tx_rdata=0, odata1=0;
always @(posedge clk) begin
	tx_rdata <= tx_mem[eth_point];
	odata1 <= raw_sr[1] ? tx_rdata : raw_sr[0] ? tx_status : 8'h51;
end
// output packet:
//   message type
//   status byte
//   buffer memory
// how about buffer length, i.e., tx_wpoint before it got erased?

// choose to pipeline output
reg_delay #(.len(n_lat-1), .dw(8)) align(.clk(clk), .gate(1'b1), .reset(1'b0),
        .din(odata1), .dout(odata));

endmodule
