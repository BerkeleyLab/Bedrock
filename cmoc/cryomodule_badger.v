`timescale 1ns / 1ns

module cryomodule_badger (
    input clk1x,
    input clk2x,
    input gmii_tx_clk,
    input gmii_rx_clk,
    input [7:0] gmii_rxd,
    input gmii_rx_dv,
    input gmii_rx_er,
    output [7:0] gmii_txd,
    output gmii_tx_en,
    output gmii_tx_er,
    // Ethernet configuration port
    input eth_cfg_clk,
    input [9:0] eth_cfg_set,
    output [7:0] eth_status
);

parameter ip ={8'd192, 8'd168, 8'd7, 8'd4};
parameter mac=48'h112233445566;
parameter jumbo_dw=14;
parameter siphash_fifo_aw=11;
parameter vmod_mode_count=3;
parameter cavity_count=2;

wire lb_clk;
wire rtefi_lb_control_strobe, rtefi_lb_control_rd, rtefi_lb_control_rd_valid;
wire [23:0] rtefi_lb_addr;
wire [31:0] rtefi_lb_data_out;
wire [31:0] rtefi_lb_data_in;


rtefi_blob #(.ip(ip), .mac(mac)) badger(
	// GMII Input (Rx)
	.rx_clk(gmii_rx_clk),
	.rxd(gmii_rxd),
	.rx_dv(gmii_rx_dv),
	.rx_er(gmii_rx_er),
	// GMII Output (Tx)
	.tx_clk(gmii_tx_clk),
	.txd(gmii_txd),
	.tx_en(gmii_tx_en),
	// Configuration
	.enable_rx(1'b1),
	.config_clk(gmii_tx_clk), .config_a(4'd0), .config_d(8'd0),
	.config_s(1'b0), .config_p(1'b0),
	// Pass-through to user modules

	.p2_nomangle(1'b0),
	.p3_addr(rtefi_lb_addr),
	.p3_control_strobe(rtefi_lb_control_strobe),
	.p3_control_rd(rtefi_lb_control_rd),
	.p3_control_rd_valid(rtefi_lb_control_rd_valid),
	.p3_data_out(rtefi_lb_data_out),
	.p3_data_in(rtefi_lb_data_in)
	// // Dumb stuff to get LEDs blinking
	// output rx_mon,
	// output tx_mon,
);


wire lb_write = rtefi_lb_control_strobe & ~rtefi_lb_control_rd & ~rtefi_lb_addr[17];
wire lb_read  = rtefi_lb_control_strobe &  rtefi_lb_control_rd & ~rtefi_lb_addr[17];
cryomodule #(
    .cavity_count(cavity_count),
    .mode_count(vmod_mode_count)
) cryomodule(
    .clk1x(clk1x),
    .clk2x(clk2x),
    // Local Bus drives both simulator and controller
    // Simulator is in the upper 16K, controller in the lower 16K words.
    .lb_clk(gmii_tx_clk),
    .lb_data(rtefi_lb_data_out),
    .lb_addr(rtefi_lb_addr[16:0]),
    .lb_write(lb_write),  // single-cycle causes a write // XXX write or strobe?
    .lb_read(lb_read),
    .lb_out(rtefi_lb_data_in)
);

endmodule
