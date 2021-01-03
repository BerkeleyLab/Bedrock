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
	output [7:0] config_a,
	output [7:0] config_d
);

assign MISO = 0;  // XXX still need to implement reads

reg [15:0] sr=0;  // shift register accumulating {a,d} from SPI master
reg din=0, csb_d1=0, csb_d2=0, sclk_d1=0, sclk_d2=0, config_w_r=0;
wire active_edge = ~csb_d1 & ~sclk_d1 & sclk_d2;  // falling edge
always @(posedge config_clk) begin
	// sync/IOB the three inputs.  Latency is not an issue.
	din <= MOSI;
	csb_d1 <= CSB;
	sclk_d1 <= SCLK;
	// need history to look for edges
	csb_d2 <= csb_d1;
	sclk_d2 <= sclk_d1;
	// update the shift register on rising edge of SCLK
	if (active_edge) sr <= {sr[14:0], din};
	// cycle the output on rising edge of CSB
	config_w_r <= csb_d1 & ~csb_d2;
end

assign config_w = config_w_r;
assign config_a = sr[15:8];
assign config_d = sr[7:0];

endmodule
