// Marble's local bus slave
// Slight adaptation of bedrock/badger/tests/lb_demo_slave.v
// Has accreted some self-diagnostic features that (probably) would
// not be part of a final production build.
// Only a few write addresses implemented for LEDs etc.,
// see logic below for local_write.
module lb_marble_slave(
	input clk,
	input [23:0] addr,
	input control_strobe,
	input control_rd,
	input [31:0] data_out,
	output [31:0] data_in,
	// Debugging
	input ibadge_clk,
	input ibadge_stb,
	input [7:0] ibadge_data,
	input obadge_stb,
	input [7:0] obadge_data,
	input xdomain_fault,
	// More debugging hooks
	input [2:0] mmc_pins,
	// Features
	input tx_mac_done,
	input [15:0] rx_mac_data,
	input [1:0] rx_mac_buf_status,
	output rx_mac_hbank,
	output cfg_d02,
	output mmc_int,
	output allow_mmc_eth_config,
	output zest_pwr_en,
`ifdef USE_I2CBRIDGE
	output twi_scl,
	inout twi_sda,
	input twi_int,
	inout twi_rst,
`endif
	output wr_dac_sclk,
	output wr_dac_sdo,
	output [1:0] wr_dac_sync,
	// Output to hardware
	output led_user_mode,
	output led1,  // PWM
	output led2  // PWM
);

// Timing hooks, can be used to speed up simulation
parameter twi_q0=5;  // 280 kbps with 125 MHz clock
parameter twi_q1=2;
parameter twi_q2=7;
parameter led_cw=10;

wire do_rd = control_strobe & control_rd;
reg dbg_rst=0;
wire [7:0] ibadge_out, obadge_out;

//`define BADGE_TRACE
`ifdef BADGE_TRACE
// Trace of input badges
badge_trace ibt(.badge_clk(ibadge_clk), .trace_reset(dbg_rst),
	.badge_stb(ibadge_stb), .badge_data(ibadge_data),
	.lb_clk(clk), .lb_addr(addr), .lb_rd(do_rd),
	.lb_result(ibadge_out)
);
// Trace of output badges
badge_trace obt(.badge_clk(clk), .trace_reset(dbg_rst),
	.badge_stb(obadge_stb), .badge_data(obadge_data),
	.lb_clk(clk), .lb_addr(addr), .lb_rd(do_rd),
	.lb_result(obadge_out)
);
`else
assign ibadge_out=0;
assign obadge_out=0;
`endif

wire [15:0] ctrace_out;
reg ctrace_start=0;
wire [0:0] ctrace_running;
`ifdef MMC_CTRACE
localparam ctrace_aw=11;
wire [ctrace_aw-1:0] ctrace_pc_mon;  // not used
ctrace #(.dw(3), .tw(13), .aw(ctrace_aw)) mmc_ctrace(
	.clk(clk), .data(mmc_pins), .start(ctrace_start),
	.running(ctrace_running), .pc_mon(ctrace_pc_mon),
	.lb_clk(clk), .lb_addr(addr[ctrace_aw-1:0]), .lb_out(ctrace_out)
);
`else
assign ctrace_out=0;
assign ctrace_running=0;
`endif

// Simple cross-domain fault counter
// Trigger originates deep inside construct.v
// Yes, clk is the right domain for this.
// Presumably there will be a burst of faults at startup as
// the FPGA and PHY clock trees come to life at different rates.
reg [15:0] xdomain_fault_count=0;
always @(posedge clk) if (xdomain_fault) xdomain_fault_count <= xdomain_fault_count + 1;

// Frequency counter
wire [31:0] tx_freq;
freq_count #(.refcnt_width(27), .freq_width(32)) f_count(.f_in(ibadge_clk),
	.sysclk(clk), .frequency(tx_freq));

// Configuration ROM
wire [15:0] config_rom_out;
config_romx rom(
	.clk(clk), .address(addr[10:0]), .data(config_rom_out)
);

// Remove any doubt about what clock domain these are in;
// also keeps reverse_json.py happy.
reg [0:0] tx_mac_done_r;
reg [1:0] rx_mac_buf_status_r;
always @(posedge clk) begin
	tx_mac_done_r <= tx_mac_done;
	rx_mac_buf_status_r <= rx_mac_buf_status;
end

// Crude uptime counter, wraps every 9.77 hours
reg led_tick=0;
reg [31:0] uptime=0;
always @(posedge clk) if (led_tick) uptime <= uptime+1;

// Optional I2C bridge instance
wire [7:0] twi_dout;
wire [2:0] twi_status;
reg [1:0] twi_ctl=0;
`ifdef USE_I2CBRIDGE
wire twi_run_stat, twi_updated, twi_err;
wire twi_freeze = twi_ctl[0];
wire twi_run_cmd = twi_ctl[1];
// Contrast with local_write, below, and
// align with read decoding for twi_dout.
wire twi_write = control_strobe & ~control_rd & (addr[23:16]==8'h04);
wire [3:0] hw_config;
i2c_chunk #(.tick_scale(twi_q0), .q1(twi_q1), .q2(twi_q2)) i2c(
	.clk(clk), .lb_addr(addr[11:0]), .lb_din(data_out[7:0]),
	.lb_write(twi_write), .lb_dout(twi_dout),
	.run_cmd(twi_run_cmd), .freeze(twi_freeze),
	.run_stat(twi_run_stat), .updated(twi_updated), .err_flag(twi_err),
	.hw_config(hw_config),
	.scl(twi_scl), .sda(twi_sda), .intp(twi_int), .rst(twi_rst)
);
assign twi_status = {twi_run_stat, twi_err, twi_updated};
`else
assign twi_dout=0;
assign twi_status=0;
assign twi_rst = hw_config[0] ? 1'b0 : 1'bz;  // three-state
`endif

// White Rabbit DAC - software-only for initial testing
// Note that chip-selects are derived from data[17:16]
// wr_dac_tick is 31.2 MHz, wr_dac_sclk is 15.6 MHz when operating
reg wr_dac_tick;  always @(posedge clk) wr_dac_tick <= &led_cc[1:0];
reg wr_dac_send=0;
wire [1:0] wr_dac_ctl=0;
wire [0:0] wr_dac_busy;
ad5662 #(.nch(2)) wr_dac(.clk(clk), .tick(wr_dac_tick),
	.data(data_out[15:0]), .sel(data_out[17:16]),
	.ctl(wr_dac_ctl), .send(wr_dac_send),
	.busy(wr_dac_busy),
	.sclk(wr_dac_sclk), .sync_(wr_dac_sync), .sdo(wr_dac_sdo)
);

// Very basic pipelining of two-cycle read process
reg [23:0] addr_r=0;
reg do_rd_r=0;
always @(posedge clk) begin
	do_rd_r <= do_rd;
	addr_r <= addr;
end

wire [31:0] hello_0 = "Hell";
wire [31:0] hello_1 = "o wo";
wire [31:0] hello_2 = "rld!";
wire [31:0] hello_3 = "(::)";
wire [31:0] mirror_out_0;

// First read cycle
reg [31:0] reg_bank_0=0, dbg_mem_out=0;
always @(posedge clk) if (do_rd) begin
	case (addr[3:0])
		4'h0: reg_bank_0 <= hello_0;
		4'h1: reg_bank_0 <= hello_1;
		4'h2: reg_bank_0 <= hello_2;
		4'h3: reg_bank_0 <= hello_3;
		4'h4: reg_bank_0 <= xdomain_fault_count;
		4'h5: reg_bank_0 <= tx_freq;
		4'h6: reg_bank_0 <= tx_mac_done_r;
		4'h7: reg_bank_0 <= rx_mac_buf_status_r;
		4'h8: reg_bank_0 <= uptime;
		4'h9: reg_bank_0 <= twi_status;
		4'ha: reg_bank_0 <= wr_dac_busy;
		4'hb: reg_bank_0 <= ctrace_running;
		default: reg_bank_0 <= "zzzz";
	endcase
end

// Second read cycle
// reverse_json.py doesn't have an address-offset feature, so put
// (read-only) reg_bank_0 at 0.  That bumps (non-newad) direct writes
// and corresponding mirror to a base address offset of 327680.
// That offset has to be accounted for in static_regmap.json.
reg [31:0] lb_data_in=0;
always @(posedge clk) if (do_rd_r) begin
	casez (addr_r)
		24'h01????: lb_data_in <= ibadge_out;
		24'h02????: lb_data_in <= obadge_out;
		24'h03????: lb_data_in <= rx_mac_data;
		24'h04????: lb_data_in <= twi_dout;
		24'h05????: lb_data_in <= mirror_out_0;
		24'h06????: lb_data_in <= ctrace_out;
		// Semi-standard address for 2K x 16 configuration ROM
		// xxx800 through xxxfff
		24'b????_????_????_1???_????_????: lb_data_in <= config_rom_out;
		24'h00????: lb_data_in <= reg_bank_0;
		default: lb_data_in <= 32'hdeadbeef;
	endcase
end

// Direct writes
reg led_user_r=0;
reg [3:0] misc_config = 4'b0000;
reg [7:0] led_1_df=0, led_2_df=0;
reg rx_mac_hbank_r=1;
// decoding corresponds to mirror readback, see notes above
wire local_write = control_strobe & ~control_rd & (addr[23:16]==5);
reg stop_sim=0;  // clearly only useful in simulation
always @(posedge clk) if (local_write) case (addr[3:0])
	1: led_user_r <= data_out;
	2: led_1_df <= data_out;
	3: led_2_df <= data_out;
	4: dbg_rst <= data_out;
	5: rx_mac_hbank_r <= data_out;
	6: stop_sim <= data_out;
	7: twi_ctl <= data_out;
	8: misc_config <= data_out;
	// 9: wr_dac
	// 10: ctrace_start
endcase
//
always @(posedge clk) begin
	wr_dac_send <= local_write & (addr[3:0] == 9);
	ctrace_start <= local_write & (addr[3:0] == 10);
end

// Mirror memory
parameter mirror_aw=5;
dpram #(.aw(mirror_aw),.dw(32)) mirror_0(
	.clka(clk), .addra(addr[mirror_aw-1:0]), .dina(data_out), .wena(local_write),
	.clkb(clk), .addrb(addr[mirror_aw-1:0]), .doutb(mirror_out_0));

// Blink the LEDs with the specified duty factor
// (your eyes won't notice the blink, because it's at 122 kHz)
reg [led_cw-1:0] led_cc=0;
reg l1=0, l2=0;
always @(posedge clk) begin
	{led_tick, led_cc} <= led_cc+1;  // free-running, no reset
	l1 <= led_cc < {led_1_df, 2'b0};
	l2 <= led_cc < {led_2_df, 2'b0};
end

// Output signal routing
assign led_user_mode = led_user_r;
assign led1 = l1;
assign led2 = l2;
assign data_in = lb_data_in;
assign rx_mac_hbank = rx_mac_hbank_r;
assign cfg_d02 = misc_config[0];
assign mmc_int = misc_config[1];
assign allow_mmc_eth_config = misc_config[2];
assign zest_pwr_en = misc_config[3];

// Bus activity trace output
`ifdef SIMULATE
reg [1:0] sr=0;
reg [23:0] addr_rr=0;
always @(posedge clk) begin
	sr <= {sr[0:0], control_strobe & control_rd};
	addr_rr <= addr_r;
	if (control_strobe & ~control_rd)
		$display("Localbus write r[%x] = %x", addr, data_out);
	if (sr[1])
		$display("Localbus read  r[%x] = %x", addr_rr, data_in);
end
`endif

endmodule
