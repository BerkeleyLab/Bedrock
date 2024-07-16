// Marble's local bus slave
// Slight adaptation of bedrock/badger/tests/lb_demo_slave.v
// Has accreted some self-diagnostic features that (probably) would
// not be part of a final production build.
// Only a few write addresses implemented for LEDs etc.
// See logic below for local_write.
module lb_marble_slave #(
	parameter USE_I2CBRIDGE = 0,
	parameter MMC_CTRACE = 0,
	parameter GPS_CTRACE = 0,
	parameter misc_config_default = 0,
	parameter use_ddr_pps = 0,
	// Timing hooks, which can be used to speed up simulation
	parameter twi_q0=6,  // 145 kbps with 125 MHz clock
	parameter twi_q1=2,
	parameter twi_q2=7,
	parameter led_cw=10,
	`ifdef MARBLE_MINI
	parameter initial_twi_file="read_trx.dat"
	`else
	parameter initial_twi_file=""
	`endif
)(
	input clk,  // 125 MHz lb_clk == tx_clk originating with 25 MHz VCXO Y1
	input [23:0] addr,
	input control_strobe,
	input control_rd,
	input [31:0] data_out,
	output [31:0] data_in,
	input aux_clk,  // presumably from 20 MHz VCXO Y3
	input clk62,
	// Debugging
	input ibadge_clk,  // 125 MHz rx_clk, also sent to frequency counter
	input ibadge_stb,
	input [7:0] ibadge_data,
	input obadge_stb,
	input [7:0] obadge_data,
	input xdomain_fault,
	input [27:0] frequency_si570,
	// More debugging hooks
	input [3:0] mmc_pins,
	input rx_category_s,
	input [3:0] rx_category,
	// Features
	input tx_mac_done,
	input [15:0] rx_mac_data,
	input [1:0] rx_mac_buf_status,
	output rx_mac_hbank,
	output cfg_d02,
	output mmc_int,
	output allow_mmc_eth_config,
	output zest_pwr_en,
	// -------
	// Ignored when USE_I2CBRIDGE=0
	// -------
	//   0 is main I2C, routes to Marble I2C bus multiplexer
	//   1 and 2 route to FMC User I/O
	//   3 is unused so far
	inout [3:0] twi_scl,
	inout [3:0] twi_sda,
	input twi_int,
	inout twi_rst,
	// -------
	output wr_dac_sclk,
	output wr_dac_sdo,
	output [1:0] wr_dac_sync,
	input [3:0] gps,
	output [3:0] ext_config,
	// Output to hardware
	inout [191:0] fmc_test,
	output [4:0] ps_sync_config,
	output [1:0] led_user_mode,
	output led1,  // PWM
	output led2  // PWM
);

wire do_rd = control_strobe & control_rd;
reg dbg_rst=0;  // purposefully unused unless BADGE_TRACE is set
wire [7:0] ibadge_out, obadge_out;

// XADC Internal Temperature Monitor
wire [15:0] xadc_temp_dout;
wire [31:0] xadc_internal_temperature;
assign xadc_internal_temperature = {16'h0000, xadc_temp_dout};

// Device DNA
wire [31:0] dna_high;
wire [31:0] dna_low;

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

wire [19:0] ctrace_out;
reg ctrace_start=0;
reg ctrace_arm=0;
wire ctrace_running;

wire [1:0] gps_ctrace_pins;
generate if (MMC_CTRACE) begin : mmc_ctrace
	// Trigger logic to look at MMC activity
	reg csb_r=0, csb_toggle=0;
	always @(posedge clk) begin
		csb_r <= mmc_pins[0];  // Note! from spi_gate.v; spi_pins_debug = {MISO, din, sclk_d1, csb_d1};
		csb_toggle <= (~mmc_pins[0] & csb_r);
		if (csb_toggle) ctrace_arm <= 0;
		if (ctrace_start) ctrace_arm <= 1;
	end
	localparam ctrace_aw=11;
	wire [ctrace_aw-1:0] ctrace_pc_mon;  // not used
	ctrace #(.dw(4), .tw(12), .aw(ctrace_aw)) mmc_ctrace(
		.clk(clk), .data(mmc_pins), .start(csb_toggle & ctrace_arm),
		.running(ctrace_running), .pc_mon(ctrace_pc_mon),
		.lb_clk(clk), .lb_addr(addr[ctrace_aw-1:0]), .lb_out(ctrace_out[15:0])
	);
        assign ctrace_out[19:16] = 0;
end else if (GPS_CTRACE) begin : gps_ctrace
	localparam ctrace_aw=14;
	wire [ctrace_aw-1:0] ctrace_pc_mon;  // not used
	ctrace #(.dw(2), .tw(18), .aw(ctrace_aw)) mmc_ctrace(
		.clk(clk), .data(gps_ctrace_pins), .start(ctrace_start),
		.running(ctrace_running), .pc_mon(ctrace_pc_mon),
		.lb_clk(clk), .lb_addr(addr[ctrace_aw-1:0]), .lb_out(ctrace_out)
	);
end else begin : no_mmc_trace
	assign ctrace_out=0;
	assign ctrace_running=0;
end endgenerate
wire [1:0] ctrace_status = {ctrace_arm, ctrace_running};

// Simple cross-domain fault counter
// Trigger originates deep inside construct.v
// Yes, clk is the right domain for this.
// Presumably there will be a burst of faults at startup as
// the FPGA and PHY clock trees come to life at different rates.
reg [15:0] xdomain_fault_count=0;
always @(posedge clk) if (xdomain_fault) xdomain_fault_count <= xdomain_fault_count + 1;

// Accumulate packet statistics
wire [19:0] rx_counters;
multi_counter #(.aw(4), .dw(20)) badger_rx_counter(
	.clk(clk), .inc(rx_category_s), .inc_addr(rx_category),
	.read_addr(addr[3:0]), .read_data(rx_counters)
);

// Frequency counter 1: Ethernet Rx referenced to Ethernet Tx
// The Ethernet Rx frequency is what's provided by the other end of the cable,
// i.e., the Ethernet switch or router.
wire [31:0] tx_freq;
freq_count #(.refcnt_width(27), .freq_width(32)) f_count1(.f_in(ibadge_clk),
	.sysclk(clk), .frequency(tx_freq));

// Frequency counter 2: aux_clk referenced to Ethernet Tx
wire [31:0] aux_freq;
freq_count #(.refcnt_width(27), .freq_width(32)) f_count2(.f_in(aux_clk),
	.sysclk(clk), .frequency(aux_freq));

// Capture Pmod GPS input pins
// gps[3] is special: that's the PPS signal that we want to
// acquire with an IDDR cell.  Leave portable code as backup
// for any synthesis that can't do our brand of IDDR.
reg [2:0] gps_pins=0;
always @(posedge clk) gps_pins <= gps[2:0];
wire [1:0] pps_in;
generate if (use_ddr_pps) begin : gen_ddr_pps
	IDDR #(
		.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")
	) iddr_pps (
		.Q1(pps_in[0]),
		.Q2(pps_in[1]),
		.C(clk), .D(gps[3]),
		.CE(1'b1), .R(1'b0), .S(1'b0)
	);
end else begin : no_gen_ddr_pps
	reg pps_dff=0;
	always @(posedge clk) pps_dff <= gps[3];
	assign pps_in = {pps_dff, pps_dff};
end endgenerate

// ctrace handling of GPS PPS (pps_in[0]) and UART (gps_pins[2])
assign gps_ctrace_pins = {pps_in[0], gps_pins[2]};

// GPS handling, which includes another frequency counter
wire gps_buf_full;
wire [7:0] gps_buf_out;
wire [27:0] gps_freq;
wire [3:0] pps_cnt;
// Ignore IDDR enhancement of PPS pin for this module
wire [3:0] gps_4pins = {pps_in[0], gps_pins};
wire [13:0] nmea_buf_status;
gps_test gps_test(.gps_pins(gps_4pins),
	.clk(clk), .lb_addr(addr[9:0]), .lb_dout(gps_buf_out),
	.buf_full(gps_buf_full), .buf_status(nmea_buf_status),
	.f_read(gps_freq), .pps_cnt(pps_cnt)
);
// Simple counter based on output of pps-lock module below (inside ad5662_lock)
// Will wrap every 1 hour, 8 minutes, 16 seconds
// Hope this will be helpful diagnosing pps dropouts
wire pps_tick;
reg [11:0] locked_pps_cnt=0;
always @(posedge clk) if (pps_tick) locked_pps_cnt <= locked_pps_cnt+1;
//
wire use_ddr_pps_bit = use_ddr_pps;
wire [9:0] gps_stat_low = {use_ddr_pps_bit, gps_buf_full, pps_cnt, gps_4pins};  // 1 + 1 + 4 + 4
wire [23:0] gps_stat = {locked_pps_cnt, 2'b00, gps_stat_low};  // 12 + 2 + 10
wire [31:0] gps_pps_data = {pps_cnt, gps_freq};

// Configuration ROM
wire [15:0] config_rom_out;
config_romx rom(
	.clk(clk), .address(addr[10:0]), .data(config_rom_out)
);

// Remove any doubt about what clock domain these are in;
// also keeps reverse_json.py happy.
reg [0:0] tx_mac_done_r=0;
always @(posedge clk) tx_mac_done_r <= tx_mac_done;
wire [1:0] rx_mac_buf_status_r;
// Instance array to cover two bits of status
reg_tech_cdc buf_status_cdc[1:0](.I(rx_mac_buf_status), .C(clk), .O(rx_mac_buf_status_r));

// Crude uptime counter, that wraps every 9.77 hours
reg led_tick=0;
reg [31:0] uptime=0;
always @(posedge clk) if (led_tick) uptime <= uptime+1;

// Optional I2C bridge instance
wire [7:0] twi_dout;
wire [4:0] twi_status;

reg [3:0] twi_ctl;
initial twi_ctl = (initial_twi_file != "") ? 4'b0010 : 4'b0000;

localparam scl_act_high = 3;  // cycles of active pull-up following rising edge
generate if (USE_I2CBRIDGE) begin : i2cb
	wire twi_run_stat, twi_analyze_run, twi_analyze_armed, twi_updated, twi_err;
	wire twi_freeze = twi_ctl[0];
	wire twi_run_cmd = twi_ctl[1];
	wire twi_trig_mode = twi_ctl[2];
	wire twi_trace_cmd = twi_ctl[3];
	// Contrast with local_write, below, and
	// align with read decoding for twi_dout.
	wire twi_write = control_strobe & ~control_rd & (addr[23:16]==8'h04);
	wire [3:0] hw_config;
	wire twi0_scl, twi_sda_drive, twi_sda_sense, twi_scl_sense;
	i2c_chunk #(.tick_scale(twi_q0), .q1(twi_q1), .q2(twi_q2),
		.initial_file(initial_twi_file)) i2c(
		.clk(clk), .lb_addr(addr[11:0]), .lb_din(data_out[7:0]),
		.lb_write(twi_write), .lb_dout(twi_dout),
		.run_cmd(twi_run_cmd), .freeze(twi_freeze), .trace_cmd(twi_trace_cmd),
		.analyze_run(twi_analyze_run), .analyze_armed(twi_analyze_armed),
		.run_stat(twi_run_stat), .updated(twi_updated), .err_flag(twi_err),
		.hw_config(hw_config), .trig_mode(twi_trig_mode),
		.scl(twi0_scl), .sda_drive(twi_sda_drive),
		.sda_sense(twi_sda_sense), .scl_sense(twi_scl_sense),
		.intp(twi_int), .rst(twi_rst)
	);
	assign twi_status = {twi_analyze_run, twi_analyze_armed, twi_run_stat, twi_err, twi_updated};
	//
	// twi_scl_l == pull pin low (dominates)
	// twi_scl_h == pull pin high
	// neither == let pin float
	wire [1:0] twi_bus_sel = hw_config[2:1];
	reg [3:0] twi_scl_l=0, twi_scl_h=0, twi_sda_r=0, twi_sda_grab=0, twi_scl_grab=0;
	reg [scl_act_high:0] twi0_scl_shf=0;
	always @(posedge clk) begin
		twi0_scl_shf <= {twi0_scl_shf[scl_act_high-1:0], twi0_scl};
		twi_scl_l <= 4'b0000;
		twi_scl_l[twi_bus_sel] <= ~twi0_scl;
		twi_scl_h <= 4'b0000;
		twi_scl_h[twi_bus_sel] <= ~twi0_scl_shf[scl_act_high];
		twi_sda_r <= 4'b1111;
		twi_sda_r[twi_bus_sel] <= twi_sda_drive;
		twi_sda_grab <= twi_sda;
		twi_scl_grab <= twi_scl;
	end
	assign twi_scl[0] = twi_scl_l[0] ? 1'b0 : twi_scl_h[0] ? 1'b1 : 1'bz;
	assign twi_scl[1] = twi_scl_l[1] ? 1'b0 : twi_scl_h[1] ? 1'b1 : 1'bz;
	assign twi_scl[2] = twi_scl_l[2] ? 1'b0 : twi_scl_h[2] ? 1'b1 : 1'bz;
	assign twi_scl[3] = twi_scl_l[3] ? 1'b0 : twi_scl_h[3] ? 1'b1 : 1'bz;
	assign twi_sda[0] = twi_sda_r[0] ? 1'bz : 1'b0;
	assign twi_sda[1] = twi_sda_r[1] ? 1'bz : 1'b0;
	assign twi_sda[2] = twi_sda_r[2] ? 1'bz : 1'b0;
	assign twi_sda[3] = twi_sda_r[3] ? 1'bz : 1'b0;
	assign twi_sda_sense = twi_sda_grab[twi_bus_sel];
	assign twi_scl_sense = twi_scl_grab[twi_bus_sel];
	assign twi_rst = hw_config[0] ? 1'b0 : 1'bz;  // three-state
end else begin : no_i2cb
	assign twi_dout=0;
	assign twi_status=0;
	assign twi_rst = 1'bz;
end endgenerate

// White Rabbit DAC - with capability of locking to PPS signal
// wr_dac_tick is 31.2 MHz, and wr_dac_sclk is 15.6 MHz when operating
reg [led_cw-1:0] led_cc=0;
reg wr_dac_tick;  always @(posedge clk) wr_dac_tick <= &led_cc[1:0];
reg wr_dac_send=0;
reg pps_config_write=0;
wire [0:0] wr_dac_busy;
wire [31:0] pps_dsp_status;
ad5662_lock wr_dac(.clk(clk), .tick(wr_dac_tick),
	.pps_in(pps_in), .pps_tick(pps_tick),
	.host_data(data_out[17:0]),
	.host_write_dac(wr_dac_send),
	.host_write_cr(pps_config_write),
	.spi_busy(wr_dac_busy),
	.dsp_status(pps_dsp_status),
	.sclk(wr_dac_sclk), .sync_(wr_dac_sync), .sdo(wr_dac_sdo)
);

// Very basic pipelining of two-cycle read process
reg [23:0] addr_r=0;
reg do_rd_r=0, do_rd_r2=0, do_rd_r3=0;
always @(posedge clk) begin
	do_rd_r <= do_rd;
	do_rd_r2 <= do_rd_r;
	do_rd_r3 <= do_rd_r2;
	addr_r <= addr;
end

wire [31:0] hello_0 = "Hell";
wire [31:0] hello_1 = "o wo";
wire [31:0] hello_2 = "rld!";
wire [31:0] hello_3 = "(::)";
wire [31:0] mirror_out_0;
reg [21:0] fmc1_test_in_l=0;
reg [21:0] fmc1_test_in_m=0;
reg [27:0] fmc1_test_in_h=0;
reg [21:0] fmc2_test_in_l=0;
reg [21:0] fmc2_test_in_m=0;
reg [27:0] fmc2_test_in_h=0;
reg [23:0] fmc2h_test_in_l=0;
reg [23:0] fmc2h_test_in_h=0;

// ==========================================
// |          Localbus Reads                |
// | NOTE: reverse_json.py reads this code  |
// | to create the json describing the      |
// | address map.                           |
// ==========================================
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
		4'hb: reg_bank_0 <= ctrace_status;
		4'hc: reg_bank_0 <= gps_stat;
		4'hd: reg_bank_0 <= gps_pps_data;
		4'he: reg_bank_0 <= pps_dsp_status;
		4'hf: reg_bank_0 <= frequency_si570;
		default: reg_bank_0 <= "zzzz";
	endcase
end

reg [31:0] reg_bank_1=0;
always @(posedge clk) if (do_rd) begin
	case (addr[3:0])
		4'h0: reg_bank_1 <= xadc_internal_temperature;
		4'h1: reg_bank_1 <= dna_high;
		4'h2: reg_bank_1 <= dna_low;
		4'h3: reg_bank_1 <= nmea_buf_status;
		4'h4: reg_bank_1 <= aux_freq;
		//  xxxx15  unused
		//  xxxx16  unused
		//  xxxx17  unused
		4'h8: reg_bank_1 <= fmc1_test_in_l;
		4'h9: reg_bank_1 <= fmc1_test_in_m;
		4'ha: reg_bank_1 <= fmc1_test_in_h;
		4'hb: reg_bank_1 <= fmc2_test_in_l;
		4'hc: reg_bank_1 <= fmc2_test_in_m;
		4'hd: reg_bank_1 <= fmc2_test_in_h;
		4'he: reg_bank_1 <= fmc2h_test_in_l;
		4'hf: reg_bank_1 <= fmc2h_test_in_h;
		default: reg_bank_1 <= "zzzz";
	endcase
end

// Second read cycle
// This code was written when reverse_json.py didn't have an
// address-offset feature, so put (read-only) reg_bank_0 at 0.
// That bumps (non-newad) direct writes
// and corresponding mirror to a base address offset of 327680.
// That offset has to be accounted for in static_regmap.json.
reg [31:0] lb_data_in=0;
always @(posedge clk) if (do_rd_r) begin
	casez (addr_r)
		// Semi-standard address for 2K x 16 configuration ROM
		// xxx800 through xxxfff
		24'b0000_0000_????_1???_????_????: lb_data_in <= config_rom_out;
		24'h00??0?: lb_data_in <= reg_bank_0;
		24'h00??1?: lb_data_in <= reg_bank_1;
		24'h01????: lb_data_in <= ibadge_out;
		24'h02????: lb_data_in <= obadge_out;
		24'h03????: lb_data_in <= rx_mac_data;
		24'h040???: lb_data_in <= twi_dout;
		24'h041???: lb_data_in <= rx_counters;
		24'h05????: lb_data_in <= mirror_out_0;
		24'h06????: lb_data_in <= ctrace_out;
		24'h07????: lb_data_in <= gps_buf_out;
		default: lb_data_in <= 32'hdeadbeef;
	endcase
end

// ==========================================
// |          Direct Localbus Writes        |
// | NOTE: this write logic is not          |
// | automatically transcribed to json.     |
// | If you want to see these in the json   |
// | register description, list them in     |
// | static_regmap.json.                    |
// ==========================================
reg [1:0] led_user_r=0;
reg [7:0] misc_config = misc_config_default;
reg [7:0] led_1_df=0, led_2_df=0;
reg rx_mac_hbank_r=1;
// decoding corresponds to mirror readback, see notes above
wire local_write = control_strobe & ~control_rd & (addr[23:16]==5);
reg stop_sim=0;  // clearly only useful in simulation
reg [4:0] ps_sync_config_r=0;
reg [71:0] fmc1_test_r=0;
reg [71:0] fmc2_test_r=0;
reg [47:0] fmc2h_test_r=0;
always @(posedge clk) if (local_write) case (addr[4:0])
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
	// 11: unused
	// 12: pps_config_write
	13: ps_sync_config_r <= data_out;
	16: fmc1_test_r[21:0] <= data_out;
	17: fmc1_test_r[43:22] <= data_out;
	18: fmc1_test_r[71:44] <= data_out;
	19: fmc2_test_r[21:0] <= data_out;
	20: fmc2_test_r[43:22] <= data_out;
	21: fmc2_test_r[71:44] <= data_out;
	22: fmc2h_test_r[23:0] <= data_out;
	23: fmc2h_test_r[47:24] <= data_out;
endcase
//
always @(posedge clk) begin
	wr_dac_send <= local_write & (addr[4:0] == 9);
	ctrace_start <= local_write & (addr[4:0] == 10);
	pps_config_write <= local_write & (addr[4:0] == 12);
end

// Mirror memory
localparam mirror_aw=5;
dpram #(.aw(mirror_aw),.dw(32)) mirror_0(
	.clka(clk), .addra(addr[mirror_aw-1:0]), .dina(data_out), .wena(local_write),
	.clkb(clk), .addrb(addr[mirror_aw-1:0]), .doutb(mirror_out_0));

// Blink the LEDs with the specified duty factor
// (your eyes won't notice the blink, because it's at 122 kHz)
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
wire drive_data_in;
assign data_in = drive_data_in ? lb_data_in : 32'bx;
assign rx_mac_hbank = rx_mac_hbank_r;
assign cfg_d02 = misc_config[0];
assign mmc_int = misc_config[1];
assign allow_mmc_eth_config = misc_config[2];
assign zest_pwr_en = misc_config[3];
assign ext_config = misc_config[7:4];
assign ps_sync_config = ps_sync_config_r;

// 3-state
genvar ix;
generate for (ix=0; ix<72; ix=ix+1) begin: fmc_lbit
	assign fmc_test[ix+0] = fmc1_test_r[ix] ? 1'b0 : 1'bz;
	assign fmc_test[ix+72] = fmc2_test_r[ix] ? 1'b0 : 1'bz;
end endgenerate
generate for (ix=0; ix<48; ix=ix+1) begin: fmc_hbit
	assign fmc_test[ix+144] = fmc2h_test_r[ix] ? 1'b0 : 1'bz;
end endgenerate
always @(posedge clk) begin
	fmc1_test_in_l <= fmc_test[21:0];
	fmc1_test_in_m <= fmc_test[43:22];
	fmc1_test_in_h <= fmc_test[71:44];
	fmc2_test_in_l <= fmc_test[93:72];
	fmc2_test_in_m <= fmc_test[115:94];
	fmc2_test_in_h <= fmc_test[143:116];
	fmc2h_test_in_l <= fmc_test[167:144];
	fmc2h_test_in_h <= fmc_test[191:168];
end

// Bus activity trace output
`ifdef SIMULATE
assign drive_data_in = do_rd_r3;
reg [2:0] sr=0;
reg [23:0] addr_rr=0;
always @(posedge clk) begin
	sr <= {sr[1:0], do_rd};
	addr_rr <= addr_r;
	if (control_strobe & ~control_rd)
		$display("Localbus write r[%x] = %x", addr, data_out);
	if (sr[2])
		$display("Localbus read  r[%x] = %x", addr_rr, data_in);
end
`else
assign drive_data_in = 1;  // Don't ask for trouble on hardware
`endif

`ifndef YOSYS
// ----------------------------------
// XADC Internal Temperature Monitor
// ----------------------------------
xadc_tempmon #(
  .SYSCLK_FREQ_HZ(125000000),
  .UPDATE_FREQ_HZ(2000)  // Update freq doesn't matter much; higher freq means smaller counter.
  ) xadc_tempmon_inst0 (
  .clk                                (clk),
  .rst                                (1'b0),            // High-true reset to XADC core
  .dout                               (xadc_temp_dout),  // Data out
  .read                               (),                // High pulse on read
  .otemp                              ()                 // Over-temp alarm
  );

// ----------------------------------
// 7-Series Device DNA Readout
// ----------------------------------
dna dna_inst0 (
  .dna_clk                            (clk62),
  .lb_clk                             (clk),
  .rst                                (1'b0),
  .start                              (1'b1),
  .done                               (),
  .dna_msb                            (dna_high),
  .dna_lsb                            (dna_low)
  );
`else
assign xadc_temp_dout=0;
assign dna_high=0;
assign dna_low=0;
`endif

endmodule
