module k7_s6(
	output       K7_S6_IO_0,
	input        K7_S6_IO_1,
	output       K7_S6_IO_2,
	input        K7_S6_IO_3,
	input        S6_TO_K7_CLK_1,
	output       s6_to_k7_clk_out,
	input  [7:0] port_50006_word_k7tos6,
	output [7:0] port_50006_word_s6tok7,
	input        port_50006_tx_available,
	output       port_50006_rx_available,
	input        port_50006_tx_complete,
	output       port_50006_rx_complete,
	output       port_50006_word_read,
	input  [7:0] port_50007_word_k7tos6,
	output [7:0] port_50007_word_s6tok7,
	output       port_50007_tx_available,
	output       port_50007_rx_available,
	output       port_50007_tx_complete,
	output       port_50007_rx_complete,
	output       port_50007_word_read,
	output       clkout,
	output       clk4xout,
	output       clk2xout
);

assign s6_to_k7_clk_out = S6_TO_K7_CLK_1;

parameter DEBUG = "true";
`ifdef SIMULATE
parameter chip_family = "SPARTAN 6";
`else
parameter chip_family = "KINTEX 7";
`endif

wire clk;
wire int_clk_4x,pll_locked;
assign clkout = clk;

wire clk_pll,int_clk;
BUFG inst_input_clk(.I(S6_TO_K7_CLK_1),.O(clk_pll));
parameter reset_duration = 12'd200;
reg [11:0] reset_counter = reset_duration;
reg pll_reset=1;
always@(posedge clk_pll) begin
	if (reset_counter==0) begin
		pll_reset <= 1'b0;
	end
	else begin
		reset_counter<= reset_counter-1;
	end
end
wire clk_2x,int_clk_2x;
wire clk_4x;
assign clk4xout = clk_4x;
assign clk2xout = clk_2x;

pll #(.DEVICE(chip_family),.clkin_period(20.0),.gmult(20),.c0div(20),.c1div(5) ,.c2div(10)) inst_pll (
	.rst(pll_reset),.locked(pll_locked),.clkin(clk_pll),.clk0(int_clk),.clk1(int_clk_4x),
	.clk2(int_clk_2x),
	.drp_clk(1'b0),.drp_write(1'b0),.drp_go(1'b0),.drp_addr(7'b0),.drp_data_in(16'b0));

BUFGCE inst_clk_bufg(.I(int_clk), .CE(pll_locked), .O(clk));
BUFGCE inst_200mhz_bufg(.I(int_clk_4x), .CE(pll_locked), .O(clk_4x));
BUFGCE inst_100mhz_bufg(.I(int_clk_2x), .CE(pll_locked), .O(clk_2x));

reg [3:0] pll_locked_4 = 0;
always@(posedge clk) begin
	pll_locked_4 <= {pll_locked_4[2:0],pll_locked};
end
wire async_reset = ~(&pll_locked_4);

tx_8b9b #(.WORD_WIDTH(8)) inst_port_50007_tx (
	.clk(clk),
	.data_out(K7_S6_IO_2),
	.word_in(port_50007_word_k7tos6),
	.word_available(port_50007_tx_available),
	.frame_complete(port_50007_tx_complete),
	.word_read(port_50007_word_read));

oversampling_rx_8b9b #(.DEVICE(chip_family),.WORD_WIDTH(8),.dbg(DEBUG)) inst_port_50007_rx (
	.async_reset(async_reset),
	.clk(clk),
	.clk_4x(clk_4x),
	.serdes_strobe(1'b1),
	.enable(1'b1),
	.data_in(K7_S6_IO_3),
	.word_out(port_50007_word_s6tok7),
	.word_write(port_50007_rx_available),
	.frame_complete(port_50007_rx_complete));

tx_8b9b #(.WORD_WIDTH(8)) inst_port_50006_tx (
	.clk(clk),
	.data_out(K7_S6_IO_0),
	.word_in(port_50006_word_k7tos6),
	.word_available(port_50006_tx_available),
	.frame_complete(port_50006_tx_complete),
	.word_read(port_50006_word_read));

oversampling_rx_8b9b #(.DEVICE(chip_family),.WORD_WIDTH(8),.dbg(DEBUG)) inst_port_50006_rx (
	.async_reset(async_reset),
	.clk(clk),
	.clk_4x(clk_4x),
	.serdes_strobe(1'b1),
	.enable(1'b1),
	.data_in(K7_S6_IO_1),
	.word_out(port_50006_word_s6tok7),
	.word_write(port_50006_rx_available),
	.frame_complete(port_50006_rx_complete));

endmodule
