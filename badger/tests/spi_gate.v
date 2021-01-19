// Want to give an off-chip microcontroller the ability to set MAC and IP
// addresses over an SPI bus.  This module acts as the translator from
// SPI slave to an 8-bit address, 8-bit data local bus.
// That super-stripped down SPI concept could be revisited if we can verify
// a suitable portable (STM32 and LPC) API on the microcontroller side.
module spi_gate(
	// pins
	input SCLK,
	input CSB,
	input MOSI,
	output MISO,
	//
	input config_clk,  // drives the only clock domain here
	output config_w,
	output config_r,
	output [7:0] config_a,
	output [7:0] config_d,
	input [7:0] tx_data
);


reg [15:0] sr=0;  // shift register accumulating {a,d} from SPI master
reg din=0, csb_d1=0, csb_d2=0, sclk_d1=0, sclk_d2=0;
reg config_w_r=0, config_r_r=0, halfway=0;
reg config_r_r1=0, config_r_r2=0;
reg [4:0] bit_cnt=0;
reg [7:0] sr_tx=0;  // could merge with sr?
wire active_edge = ~csb_d1 & ~sclk_d1 & sclk_d2;  // falling edge
reg active_edge1=0, active_edge2=0;
always @(posedge config_clk) begin
	// sync/IOB the three inputs.  Latency is not an issue.
	din <= MOSI;
	csb_d1 <= CSB;
	sclk_d1 <= SCLK;
	// need history to look for edges
	csb_d2 <= csb_d1;
	sclk_d2 <= sclk_d1;
	// update the shift register on active edge of SCLK
	if (active_edge) begin
		sr <= {sr[14:0], din};
		bit_cnt <= bit_cnt + 1;
		halfway <= |bit_cnt[4:3];
	end
	active_edge1 <= active_edge;
	active_edge2 <= active_edge1;
	if (active_edge2) sr_tx <= {sr_tx[6:0], 1'b0};
	// cycle the output on rising edge of CSB
	config_w_r <= csb_d1 & ~csb_d2;
	// WIP: flag the halfway point
	config_r_r <= active_edge & (bit_cnt==7);
	config_r_r1 <= config_r_r;
	if (config_r_r1) sr_tx <= tx_data;
	if (csb_d2 & ~csb_d1) bit_cnt <= 0;
end

assign config_w = config_w_r;
assign config_r = config_r_r;
assign config_a = halfway ? sr[15:8] : sr[7:0];
assign config_d = sr[7:0];
assign MISO = sr_tx[7];
// MISO transitions three cycles (24 ns) after falling edge of SCLK
// (as latched in the IOB as sclk_d1)

endmodule
