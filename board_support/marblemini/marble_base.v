// Marble base, mostly copied from hw_test.v
// Instantiates rtefi_blob and support code
// Needs to be kept 100% portable/synthesizable
module marble_base(

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
	output MISO,
	output mmc_int,

	// SPI boot flash programming port
	output boot_clk,
	output boot_cs,
	output boot_mosi,
	input boot_miso,
	output cfg_d02,

	// One I2C bus, everything gatewayed through a TCA9548
	output [3:0] twi_scl,
	inout  [3:0] twi_sda,
	output TWI_RST,
	input  TWI_INT,

	// White Rabbit DAC
	output WR_DAC_SCLK,
	output WR_DAC_DIN,
	output WR_DAC1_SYNC,
	output WR_DAC2_SYNC,

	// Simulation-only, please ignore in synthesis
	output in_use,

        // Local bus for an external application
        // Define clock domain
        output lb_clk,
        output [23:0] lb_addr,
        output lb_strobe,
        output lb_rd,
        output lb_write,
        output lb_rd_valid,
	// output [read_pipe_len:0] control_pipe_rd,
        output [31:0] lb_data_out,
        input [31:0] lb_data_in,

	// Something physical
	output [131:0] fmc_test,
	output ZEST_PWR_EN,
	output [7:0] LED
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
wire enable_rx, config_s, config_p;
wire [3:0] config_a;
wire [7:0] config_d;
spi_gate spi(
	.MOSI(MOSI), .SCLK(SCLK), .CSB(CSB),
	.enable_rx(enable_rx),
	.config_clk(config_clk), .config_s(config_s), .config_p(config_p),
	.config_a(config_a), .config_d(config_d)
);
assign MISO = 0;  // XXX fixme

wire led_user_mode, l1, l2;
// Local bus
assign lb_clk = tx_clk;
//wire [23:0] lb_addr;
wire [31:0] lb_data_muxed;
wire lb_control_strobe, lb_control_rd, lb_control_rd_valid;
assign lb_strobe = lb_control_strobe;
assign lb_rd = lb_control_rd;
assign lb_rd_valid = lb_control_rd_valid;
assign lb_write = lb_control_strobe & ~lb_control_rd;

// Debugging hooks
wire ibadge_stb, obadge_stb;
wire [7:0] ibadge_data, obadge_data;
wire xdomain_fault;
wire tx_mac_done;
wire [15:0] rx_mac_data;
wire rx_mac_hbank;
wire [1:0] rx_mac_buf_status;
wire allow_mmc_eth_config;
wire [31:0] lb_slave_data_read;

//
lb_marble_slave slave(
	.clk(lb_clk), .addr(lb_addr),
	.control_strobe(lb_control_strobe), .control_rd(lb_control_rd),
	.data_out(lb_data_out), .data_in(lb_slave_data_read),
	.ibadge_clk(rx_clk),
	.ibadge_stb(ibadge_stb), .ibadge_data(ibadge_data),
	.obadge_stb(obadge_stb), .obadge_data(obadge_data),
	.xdomain_fault(xdomain_fault),
	.mmc_pins({MOSI, SCLK, CSB}),
	.tx_mac_done(tx_mac_done), .rx_mac_data(rx_mac_data),
	.rx_mac_buf_status(rx_mac_buf_status), .rx_mac_hbank(rx_mac_hbank),
`ifdef USE_I2CBRIDGE
	.twi_scl(twi_scl), .twi_sda(twi_sda),
	.twi_int(TWI_INT), .twi_rst(TWI_RST),
`endif
	.wr_dac_sclk(WR_DAC_SCLK), .wr_dac_sdo(WR_DAC_DIN),
	.wr_dac_sync({WR_DAC2_SYNC, WR_DAC1_SYNC}),
	.cfg_d02(cfg_d02),
	.mmc_int(mmc_int),
	.zest_pwr_en(ZEST_PWR_EN),
	.allow_mmc_eth_config(allow_mmc_eth_config),
	.fmc_test(fmc_test),
	.led_user_mode(led_user_mode), .led1(l1), .led2(l2)
);

reg [23:0] p3_lb_addr_d;
reg p3_use_app_rd;

always @(posedge lb_clk) begin
	p3_lb_addr_d <= lb_addr;
	p3_use_app_rd <= p3_lb_addr_d[23:20] == 1;
end

wire [31:0] p3_lb_data_in = p3_use_app_rd ? lb_data_in : lb_slave_data_read;

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

// Note special-case enabling of config controls from MMC!
// Expect allow_mmc_eth_config to be 1 in the long run,
// but the 0 case is very interesting for debugging, and in fact
// is the power-on default for now.
// Simple combinational logic is OK, since all signals are in tx_clk domain
// (config_clk == tx_clk == lb_clk).

	.enable_rx(enable_rx | ~allow_mmc_eth_config),
	.config_clk(config_clk),
	.config_s(config_s & allow_mmc_eth_config),
	.config_p(config_p & allow_mmc_eth_config),
	.config_a(config_a), .config_d(config_d),

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
	.p3_data_out(lb_data_out), .p3_data_in(p3_lb_data_in),
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
// wire led0 = led_user_mode ? l1 : rx_heartbeat[26];
// wire led1 = led_user_mode ? l2 : tx_heartbeat[26];
wire rx_led, tx_led;
activity rx_act(.clk(rx_clk), .trigger(rx_mon), .led(rx_led));
activity tx_act(.clk(tx_clk), .trigger(tx_mon), .led(tx_led));
wire rx_h = rx_heartbeat[26];
wire tx_h = tx_heartbeat[26];
assign LED = {~tx_h, tx_h, ~rx_h, rx_h, tx_led, rx_led, l2, l1};

// Keep the PHY's reset pin low for the first 33 ms
reg phy_rb=0;
always @(posedge tx_clk) begin
	if (tx_heartbeat[21]) phy_rb <= 1;
	if (~clk_locked) phy_rb <= 0;
end
assign phy_rstn = phy_rb;

// One weird hack, even works in Verilator!
always @(posedge tx_clk) begin
	if (slave.stop_sim & ~in_use) begin
		$display("hw_test_tb:  stopping based on localbus request");
		$finish();
	end
end

endmodule
