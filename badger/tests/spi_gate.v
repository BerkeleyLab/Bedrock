// Gives a (fictional?) off-chip microcontroller the ability to set MAC and IP
// addresses over an SPI bus.  This module acts as the SPI slave.
module spi_gate(
	// pins
	input SCLK,
	input CSB,
	input MOSI,
	// connect these to rtefi_pipe
	output enable_rx,
	input config_clk,  // drives the only clock domain here
	output config_s,
	output config_p,
	output [3:0] config_a,
	output [7:0] config_d
);

parameter default_enable_rx = 1;

reg [15:0] sr=0;  // shift register accumulating {a,d} from SPI master
reg din=0, csb_d1=0, csb_d2=0, sclk_d1=0, sclk_d2=0, config_s_r=0;
reg enable_r=default_enable_rx;  // special case initialization
always @(posedge config_clk) begin
	// sync/IOB the three inputs.  Latency is not an issue.
	din <= MOSI;
	csb_d1 <= CSB;
	sclk_d1 <= SCLK;
	// need history to look for edges
	csb_d2 <= csb_d1;
	sclk_d2 <= sclk_d1;
	// update the shift register on rising edge of SCLK
	if (~csb_d1 & sclk_d1 & ~sclk_d2) sr <= {sr[14:0], din};
	// cycle the output on rising edge of CSB
	config_s_r <= csb_d1 & ~csb_d2;
	if (config_s_r && (sr[15:12] == 2)) enable_r <= sr[0];
end

// 16-bit sr semantics:
//   0 0 0 1 a a a a d d d d d d d d  ->  set MAC/IP config[a] = D
//   0 0 1 0 x x x x x x x x x x x V  ->  set enable_rx to V
//   0 0 1 1 a a a a d d d d d d d d  ->  set UDP port config[a] = D
assign config_s = config_s_r && (sr[15:12] == 1);
assign config_p = config_s_r && (sr[15:12] == 3);
assign config_a = sr[11:8];
assign config_d = sr[7:0];
assign enable_rx = enable_r;

endmodule
