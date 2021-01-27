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

	// SPI boot flash programming port
	output boot_clk,
	output boot_cs,
	output boot_mosi,
	input boot_miso,

	// Simulation-only, please ignore in synthesis
	output in_use,

	// Something physical
	input RESET,
	output [3:0] LED
);

`ifdef VERILATOR
parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd4};  // 192.168.7.4
parameter [47:0] mac = 48'h12555500012d;
`else
`ifdef YOSYS
parameter [31:0] ip = {8'd192, 8'd168, 8'd19, 8'd9};  // 192.168.19.9
parameter [47:0] mac = 48'h12555500022d;
`else
parameter [31:0] ip = {8'd192, 8'd168, 8'd19, 8'd8};  // 192.168.19.8
parameter [47:0] mac = 48'h12555500012d;
`endif
`endif

wire tx_clk = vgmii_tx_clk;
wire rx_clk = vgmii_rx_clk;

// Configuration port
wire config_clk = tx_clk;
wire config_w;
wire [7:0] config_a;
wire [7:0] config_d;
wire [7:0] spi_return=0;
spi_gate spi(
	.MOSI(MOSI), .SCLK(SCLK), .CSB(CSB),
	.config_clk(config_clk), .config_w(config_w),
	.config_a(config_a), .config_d(config_d), .tx_data(spi_return)
);

// Map generic configuration bus to application
// 16-bit SPI word semantics:
//   0 0 0 1 a a a a d d d d d d d d  ->  set MAC/IP config[a] = D
//   0 0 1 0 x x x x x x x x x x x V  ->  set enable_rx to V
//   0 0 1 1 a a a a d d d d d d d d  ->  set UDP port config[a] = D
parameter default_enable_rx = 1;
reg enable_rx=default_enable_rx;  // special case initialization
always @(posedge config_clk) if (config_w && (config_a[7:4] == 2)) enable_rx <= config_d[0];
wire config_s = config_w && (config_a[7:4] == 1);
wire config_p = config_w && (config_a[7:4] == 3);

wire led_user_mode, l1, l2;
// Local bus
wire lb_clk = tx_clk;
wire [23:0] lb_addr;
wire [31:0] lb_data_out, lb_data_in;
wire lb_control_strobe, lb_control_rd, lb_control_rd_valid;
// Debugging hooks
wire ibadge_stb, obadge_stb;
wire [7:0] ibadge_data, obadge_data;
wire xdomain_fault;
wire tx_mac_done;
wire [15:0] rx_mac_data;
wire rx_mac_hbank;
wire [1:0] rx_mac_buf_status;
//
lb_demo_slave slave(.clk(lb_clk), .addr(lb_addr),
	.control_strobe(lb_control_strobe), .control_rd(lb_control_rd),
	.data_out(lb_data_out), .data_in(lb_data_in),
	.ibadge_clk(rx_clk),
	.ibadge_stb(ibadge_stb), .ibadge_data(ibadge_data),
	.obadge_stb(obadge_stb), .obadge_data(obadge_data),
	.xdomain_fault(xdomain_fault),
	.tx_mac_done(tx_mac_done), .rx_mac_data(rx_mac_data),
	.rx_mac_buf_status(rx_mac_buf_status), .rx_mac_hbank(rx_mac_hbank),
	.led_user_mode(led_user_mode), .led1(l1), .led2(l2)
);

// MAC master
// Clearly not useful in the long run to drive this only from
// the localbus, but doing so makes for a much lighter-weight test
// than installing a real soft-core CPU.
parameter tx_mac_aw=10;
wire host_clk = lb_clk;
wire host_write = lb_control_strobe & ~lb_control_rd & (lb_addr[23:20]==1);
wire [tx_mac_aw:0] host_waddr = lb_addr[tx_mac_aw:0];
wire [15:0] host_wdata = lb_data_out[15:0];
wire [10:0] host_raddr = lb_addr[10:0];  // for Rx MAC

// Rx MAC with DPRAM
wire [7:0] rx_mac_d;
wire [11:0] rx_mac_a;
wire rx_mac_wen;
wire rx_mac_accept, rx_mac_status_s;
wire [7:0] rx_mac_status_d;
base_rx_mac rx_mac(
	// host access
	.host_clk(host_clk), .host_raddr(host_raddr),
	.host_rdata(rx_mac_data),
	// connection to Rx MAC port
	.rx_clk(vgmii_rx_clk),
	.rx_mac_d(rx_mac_d), .rx_mac_a(rx_mac_a), .rx_mac_wen(rx_mac_wen),
	.rx_mac_accept(rx_mac_accept),
	.rx_mac_status_d(rx_mac_status_d), .rx_mac_status_s(rx_mac_status_s)
);

// memory and control signals are handled external to mac_subset.v
// in this branch, which the testbenches were not designed for ...
// the next few lines are patching that up
wire [tx_mac_aw-1:0] host_tx_raddr;
wire [15:0] host_tx_rdata;
wire [tx_mac_aw-1:0] buf_start_addr;
wire tx_mac_start;
mac_compat_dpram #(
	.mac_aw(tx_mac_aw)
) mac_compat_dpram_inst (
	.host_clk(host_clk),
	.host_waddr(host_waddr),
	.host_write(host_write),
	.host_wdata(host_wdata),
// ----------------------------
	.tx_clk(tx_clk),
	.host_raddr(host_tx_raddr),
	.host_rdata(host_tx_rdata),
	.buf_start_addr(buf_start_addr),
	.tx_mac_start(tx_mac_start)
);

// Instantiate the Real Work
parameter enable_bursts=1;

wire rx_mon, tx_mon;
wire boot_busy, blob_in_use;
rtefi_blob #(.ip(ip), .mac(mac), .mac_aw(tx_mac_aw), .p3_enable_bursts(enable_bursts)) rtefi(
	.rx_clk(vgmii_rx_clk), .rxd(vgmii_rxd),
	.rx_dv(vgmii_rx_dv), .rx_er(vgmii_rx_er),
	.tx_clk(tx_clk) , .txd(vgmii_txd),
	.tx_en(vgmii_tx_en),  // no vgmii_tx_er
	.enable_rx(enable_rx),
	.config_clk(config_clk), .config_s(config_s), .config_p(config_p),
	.config_a(config_a[3:0]), .config_d(config_d),

	// .host_clk(host_clk), .host_write(host_write),
	// .host_waddr(host_waddr), .host_wdata(host_wdata),
	.host_raddr(host_tx_raddr),
	.host_rdata(host_tx_rdata),
	.buf_start_addr(buf_start_addr),
	.tx_mac_start(tx_mac_start),

	.tx_mac_done(tx_mac_done),
	.rx_mac_d(rx_mac_d), .rx_mac_a(rx_mac_a), .rx_mac_wen(rx_mac_wen),
	.rx_mac_hbank(rx_mac_hbank), .rx_mac_buf_status(rx_mac_buf_status),
	.rx_mac_accept(rx_mac_accept),
	.rx_mac_status_d(rx_mac_status_d), .rx_mac_status_s(rx_mac_status_s),
	.ibadge_stb(ibadge_stb), .ibadge_data(ibadge_data),
	.obadge_stb(obadge_stb), .obadge_data(obadge_data),
	.xdomain_fault(xdomain_fault),
	.p2_nomangle(1'b0),
	.p3_addr(lb_addr), .p3_control_strobe(lb_control_strobe),
	.p3_control_rd(lb_control_rd), .p3_control_rd_valid(lb_control_rd_valid),
	.p3_data_out(lb_data_out), .p3_data_in(lb_data_in),
	.p4_spi_clk(boot_clk), .p4_spi_cs(boot_cs),
	.p4_spi_mosi(boot_mosi), .p4_spi_miso(boot_miso),
	.p4_busy(boot_busy),
	.rx_mon(rx_mon), .tx_mon(tx_mon), .in_use(blob_in_use)
);
assign vgmii_tx_er=1'b0;
assign in_use = blob_in_use | boot_busy;

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

// One weird hack, even works in Verilator!
// But trips up synthesis on XST.
`ifdef SIMULATE
always @(posedge tx_clk) begin
	if (slave.stop_sim & ~in_use) begin
		$display("hw_test_tb:  stopping based on localbus request");
		$finish();
	end
end
`endif

endmodule
