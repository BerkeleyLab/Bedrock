// Hardware Test
// Instantiates rtefi_blob and support code
module hw_test(

	// GMII Tx port
	input vgmii_tx_clk,
	output [7:0] vgmii_txd,
	output vgmii_tx_en,
	output vgmii_tx_er,

	// GMII Rx port
	input vgmii_rx_clk,
	input [7:0] vgmii_rxd,
	input vgmii_rx_er,
	input vgmii_rx_dv,

	// Auxiliary I/O and status
	output phy_rstn,
	input clk_locked,

	// SPI pins, can give access to configuration
	input SCLK,
	input CSB,
	input MOSI,

	// Something physical
	input RESET,
	output [3:0] LED
);

`ifdef YOSYS
parameter [31:0] ip = {8'd192, 8'd168, 8'd19, 8'd9};  // 192.168.19.9
parameter [47:0] mac = 48'h12555500022d;
`else
parameter [31:0] ip = {8'd192, 8'd168, 8'd19, 8'd8};  // 192.168.19.8
parameter [47:0] mac = 48'h12555500012d;
`endif

wire tx_clk = vgmii_tx_clk;
wire rx_clk = vgmii_rx_clk;

// Configuration port
wire config_clk = tx_clk;
wire enable_rx, config_s, config_p;
wire [3:0] config_a;
wire [7:0] config_d;
spi_gate spi(
	.MOSI(MOSI), .SCLK(SCLK), .CSB(CSB),
	.enable_rx(enable_rx),
	.config_clk(config_clk), .config_s(config_s), .config_p(config_p),
	.config_a(config_a), .config_d(config_d)
);

wire led_user_mode, l1, l2;
// Local bus
wire [23:0] lb_addr;
wire [31:0] lb_data_out, lb_data_in;
wire lb_control_strobe, lb_control_rd, lb_control_rd_valid;
// Debugging hooks
wire ibadge_stb, obadge_stb;
wire [7:0] ibadge_data, obadge_data;
wire xdomain_fault;
//
lb_demo_slave slave(.clk(tx_clk), .addr(lb_addr),
	.control_strobe(lb_control_strobe), .control_rd(lb_control_rd),
	.data_out(lb_data_out), .data_in(lb_data_in),
	.ibadge_clk(rx_clk),
	.ibadge_stb(ibadge_stb), .ibadge_data(ibadge_data),
	.obadge_stb(obadge_stb), .obadge_data(obadge_data),
	.xdomain_fault(xdomain_fault),
	.led_user_mode(led_user_mode), .led1(l1), .led2(l2)
);

// Instantiate the Real Work
wire rx_mon, tx_mon;
rtefi_blob #(.ip(ip), .mac(mac)) rtefi(
	.rx_clk(vgmii_rx_clk), .rxd(vgmii_rxd),
	.rx_dv(vgmii_rx_dv), .rx_er(vgmii_rx_er),
	.tx_clk(tx_clk) , .txd(vgmii_txd),
	.tx_en(vgmii_tx_en),  // no vgmii_tx_er
	.enable_rx(enable_rx),
	.config_clk(config_clk), .config_s(config_s), .config_p(config_p),
	.config_a(config_a), .config_d(config_d),
	.ibadge_stb(ibadge_stb), .ibadge_data(ibadge_data),
	.obadge_stb(obadge_stb), .obadge_data(obadge_data),
	.xdomain_fault(xdomain_fault),
	.p2_nomangle(1'b0),
	.p3_addr(lb_addr), .p3_control_strobe(lb_control_strobe),
	.p3_control_rd(lb_control_rd), .p3_control_rd_valid(lb_control_rd_valid),
	.p3_data_out(lb_data_out), .p3_data_in(lb_data_in),
	.rx_mon(rx_mon), .tx_mon(tx_mon)
);
assign vgmii_tx_er=1'b0;

// Heartbeats and other LED
reg [26:0] rx_heartbeat=0, tx_heartbeat=0;
always @(posedge rx_clk) rx_heartbeat <= rx_heartbeat+1;
always @(posedge tx_clk) tx_heartbeat <= tx_heartbeat+1;
wire led0 = led_user_mode ? l1 : rx_heartbeat[26];
wire led1 = led_user_mode ? l2 : tx_heartbeat[26];
wire rx_led, tx_led;
activity rx_act(.clk(rx_clk), .trigger(rx_mon), .led(rx_led));
activity tx_act(.clk(tx_clk), .trigger(tx_mon), .led(tx_led));
assign LED = {tx_led, rx_led, led0, led1};

// Keep the PHY's reset pin low for the first 33 ms
reg phy_rb=0;
always @(posedge tx_clk) begin
	if (tx_heartbeat[21]) phy_rb <= 1;
	if (~clk_locked) phy_rb <= 0;
end
assign phy_rstn = phy_rb;

endmodule
