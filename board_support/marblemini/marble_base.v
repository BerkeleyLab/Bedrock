// Marble base, mostly copied from hw_test.v
// Instantiates rtefi_blob and support code
// Needs to be kept 100% portable/synthesizable

module marble_base (
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
	input aux_clk,
	input clk62,
	input cfg_clk,
	output phy_rstn,
	input clk_locked,
	input si570,

	// SPI pins to on-board microcontroller; can give access to configuration
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

	// One I2C bus; everything gatewayed through a TCA9548A
	inout  [3:0] twi_scl,
	inout  [3:0] twi_sda,
	inout  TWI_RST,
	input  TWI_INT,

	// White Rabbit compatible DAC subsystem controlling VCXOs
	output WR_DAC_SCLK,
	output WR_DAC_DIN,
	output WR_DAC1_SYNC,
	output WR_DAC2_SYNC,

	// UART to USB
	// The RxD and TxD directions are with respect
	// to the USB/UART chip, not the FPGA!
	// Note that the freq_demo feature doesn't actually use FPGA_TxD.
	// If you don't connect anything to FPGA_RxD, the synthesizer
	// will drop the whole freq_demo feature.
	output FPGA_RxD,
	input FPGA_TxD,

	// Digilent GPS
	input [3:0] GPS,

	// Placeholder for configuring external devices
	output [3:0] ext_config,

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
	inout [191:0] fmc_test,
	output ZEST_PWR_EN,
	output [2:0] ps_sync,
	output [7:0] LED
);

parameter USE_I2CBRIDGE = 1;
parameter MMC_CTRACE = 1;
parameter GPS_CTRACE = 0;
parameter use_ddr_pps = 0;
parameter misc_config_default = 0;
parameter default_enable_rx = 1;

`ifdef VERILATOR
parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd4};  // 192.168.7.4
parameter [47:0] mac = 48'h12555500012d;
`else
`ifdef YOSYS
parameter [31:0] ip = {8'd192, 8'd168, 8'd19, 8'd9};  // 192.168.19.9
parameter [47:0] mac = 48'h12555500022d;
`else
parameter [31:0] ip = {8'd192, 8'd168, 8'd19, 8'd10};  // 192.168.19.10
parameter [47:0] mac = 48'h12555500032d;
`endif
`endif

// Basic clock setup
wire tx_clk = vgmii_tx_clk;
wire rx_clk = vgmii_rx_clk;

// Local bus
wire lb_control_strobe, lb_control_rd, lb_control_rd_valid;  // outputs from rtefi_blob
assign lb_clk = tx_clk;
assign lb_strobe = lb_control_strobe;
wire config_clk = tx_clk;
assign lb_write = lb_control_strobe & ~lb_control_rd;
assign lb_rd_valid = lb_control_rd_valid;
assign lb_rd = lb_control_rd;

// Signals provided by mmc_mailbox
wire [3:0] spi_pins_debug;
wire enable_rx;
wire [7:0] mbox_out2;
wire config_s, config_p;
wire [7:0] config_a, config_d;

// Actual mmc_mailbox instance
mmc_mailbox #(
  .DEFAULT_ENABLE_RX(default_enable_rx)
  ) mailbox_i (
  .clk(config_clk), // input
  // localbus
  .lb_addr(lb_addr[10:0]), // input [10:0]
  .lb_din(lb_data_out[7:0]), // input [7:0]
  .lb_dout(mbox_out2), // output [7:0]
  .lb_write(lb_write), // input
  .lb_control_strobe(lb_control_strobe), // input
  // SPI PHY
  .sck(SCLK), // input
  .ncs(CSB), // input
  .pico(MOSI), // input
  .poci(MISO), // output
  // Config pins for badger (rtefi) interface
  .config_s(config_s), // output
  .config_p(config_p), // output
  .config_a(config_a), // output [7:0]
  .config_d(config_d), // output [7:0]
  // Special pins
  .enable_rx(enable_rx), // output
  .spi_pins_debug(spi_pins_debug) // {MISO, din, sclk_d1, csb_d1};
);

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

// for looking at start-up frequency of SI570
wire [27:0] frequency_si570;
freq_count freq_cnt_si570(.f_in(si570), .sysclk(lb_clk), .frequency(frequency_si570));

// Signals provided to lb_marble_slave
wire [3:0] rx_category_rx, rx_category;
wire rx_category_s_rx, rx_category_s;

// Signals provided by lb_marble_slave
wire [1:0] led_user_mode;
wire l1, l2;
wire [4:0] ps_sync_config;

// Actual lb_marble_slave instance
lb_marble_slave #(
	.USE_I2CBRIDGE(USE_I2CBRIDGE),
	.MMC_CTRACE(MMC_CTRACE),
	.GPS_CTRACE(GPS_CTRACE),
	.use_ddr_pps(use_ddr_pps),
	.misc_config_default(misc_config_default)
) slave(
	.clk(lb_clk), .addr(lb_addr),
	.control_strobe(lb_control_strobe), .control_rd(lb_control_rd),
	.data_out(lb_data_out), .data_in(lb_slave_data_read),
	.aux_clk(aux_clk), .clk62(clk62),
	.ibadge_clk(rx_clk),
	.ibadge_stb(ibadge_stb), .ibadge_data(ibadge_data),
	.obadge_stb(obadge_stb), .obadge_data(obadge_data),
	.xdomain_fault(xdomain_fault),
	.mmc_pins(spi_pins_debug),
	.rx_category_s(rx_category_s), .rx_category(rx_category),
	.tx_mac_done(tx_mac_done), .rx_mac_data(rx_mac_data),
	.rx_mac_buf_status(rx_mac_buf_status), .rx_mac_hbank(rx_mac_hbank),
	.twi_scl(twi_scl), .twi_sda(twi_sda),
	.twi_int(TWI_INT), .twi_rst(TWI_RST),
	.wr_dac_sclk(WR_DAC_SCLK), .wr_dac_sdo(WR_DAC_DIN),
	.wr_dac_sync({WR_DAC2_SYNC, WR_DAC1_SYNC}),
	.cfg_d02(cfg_d02),
	.mmc_int(mmc_int),
	.zest_pwr_en(ZEST_PWR_EN),
	.allow_mmc_eth_config(allow_mmc_eth_config),
	.fmc_test(fmc_test),
	.gps(GPS), .ext_config(ext_config), .frequency_si570(frequency_si570),
	.ps_sync_config(ps_sync_config),
	.led_user_mode(led_user_mode), .led1(l1), .led2(l2)
);

// Delegate part of the address space to application code outside this module
reg [23:0] p3_lb_addr_d;
reg p3_use_app_rd=0, p3_use_mbox_rd=0;
always @(posedge lb_clk) begin
	p3_lb_addr_d <= lb_addr;
	p3_use_app_rd <= p3_lb_addr_d[23:20] == 1;
	p3_use_mbox_rd <= p3_lb_addr_d[23:20] == 2;
end
wire [31:0] p3_lb_data_in = p3_use_mbox_rd ? mbox_out2 : p3_use_app_rd ? lb_data_in : lb_slave_data_read;

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

// Be careful with clock domains:
// rtefi_blob uses this in rx_clk, so send it a registered value.
reg enable_rx_r=0;  always @(posedge tx_clk) enable_rx_r <= enable_rx | ~allow_mmc_eth_config;

// Instantiate the Real Work
parameter enable_bursts=1;

wire [3:0] scanner_debug;
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

	.enable_rx(enable_rx_r),
	.config_clk(config_clk),
	.config_s(config_s & allow_mmc_eth_config),
	.config_p(config_p & allow_mmc_eth_config),
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
	.scanner_debug(scanner_debug),
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

// Frequency counter demo to UART
wire [3:0] unk_clk = {cfg_clk, si570, aux_clk, rx_clk};
freq_demo freq_demo(
	.refclk(tx_clk), .unk_clk(unk_clk),
	.uart_tx(FPGA_RxD), .uart_rx(FPGA_TxD)
);

// For statistics-gathering purposes
packet_categorize i_categorize(.clk(vgmii_rx_clk),
	.strobe(rx_mac_status_s), .status(rx_mac_status_d),
	.strobe_o(rx_category_s_rx), .category(rx_category_rx)
);
data_xdomain #(.size(4)) x_category(
	.clk_in(vgmii_rx_clk), .gate_in(rx_category_s_rx), .data_in(rx_category_rx),
	.clk_out(lb_clk), .gate_out(rx_category_s), .data_out(rx_category)
);

// Heartbeats and other LED
reg [26:0] rx_heartbeat=0, tx_heartbeat=0;
always @(posedge rx_clk) rx_heartbeat <= rx_heartbeat+1;
always @(posedge tx_clk) tx_heartbeat <= tx_heartbeat+1;
wire led0 = led_user_mode ? l1 : rx_heartbeat[26];
wire led1 = led_user_mode ? l2 : tx_heartbeat[26];
wire rx_led, tx_led;
activity rx_act(.clk(rx_clk), .trigger(rx_mon), .led(rx_led));
activity tx_act(.clk(tx_clk), .trigger(tx_mon), .led(tx_led));
wire rx_h = rx_heartbeat[26];
wire tx_h = tx_heartbeat[26];
reg mod=0, reset=0;
reg [31:0] cnt=0;
always @(posedge rx_clk) begin
    cnt <= reset ? 32'h0 : cnt + 1'b1;
    mod <= cnt[0];
end
assign LED = (led_user_mode==2) ? cnt[30:23] & {8{mod}} : {~tx_h, tx_h, ~rx_h, rx_h, tx_led, rx_led, led1, led0};

// Keep the PHY's reset pin low for the first 33 ms
reg phy_rb=0;
always @(posedge tx_clk) begin
	if (tx_heartbeat[21]) phy_rb <= 1;
	if (~clk_locked) phy_rb <= 0;
end
assign phy_rstn = phy_rb;

ltm_sync ltm_sync_i(.clk(tx_clk),
	.ps_config(ps_sync_config), .ps_sync(ps_sync));

// One weird hack, even works in Verilator!
`ifndef YOSYS
always @(posedge tx_clk) begin
	if (slave.stop_sim & ~in_use) begin
		$display("marble_base:  stopping based on localbus request");
		$finish(0);
	end
end
`endif

endmodule
