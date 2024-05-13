// Mostly useless demo of a local bus slave
// just to make it clear that the master is alive (or not)
// Has accreted some self-diagnostic features that (probably) would
// not be part of a final production build.
// Only a few write addresses implemented for LEDs etc., addr[23:16]==0.
module lb_demo_slave(
	input clk,  // 125 MHz lb_clk == tx_clk
	input [23:0] addr,
	input control_strobe,
	input control_rd,
	input [31:0] data_out,
	output [31:0] data_in,
	// Debugging
	input ibadge_clk,  // 125 MHz rx_clk, also sent to frequency counter
	input ibadge_stb,
	input [7:0] ibadge_data,
	input obadge_stb,
	input [7:0] obadge_data,
	input xdomain_fault,
	input rx_category_s,
	input [3:0] rx_category,
	// Features
	input tx_mac_done,
	input [15:0] rx_mac_data,
	input [1:0] rx_mac_buf_status,
	output rx_mac_hbank,
	// See cluster_wrap.v
	output [31:0] scratch_out,
	input [31:0] scratch_in,
	// Output to hardware
	output led_user_mode,
	output led1,  // PWM
	output led2  // PWM
);

wire do_rd = control_strobe & control_rd;
reg dbg_rst=0;  // purposefully unused unless BADGE_TRACE is set
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

// Configuration ROM
wire [15:0] config_rom_out;
fake_config_romx rom(
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

// See cluster_wrap.v
// Make sure synthesis knows this signal is in right clock domain
reg [31:0] scratch_in_r=0;
always @(posedge clk) scratch_in_r <= scratch_in;

// ==========================================
// |          Localbus Decoding             |
// | Supposedly consistent with address map |
// | embedded in fake_config_romx.v.        |
// | See the Makefile for more comments.    |
// ==========================================

// NOTE: The next line is parsed by bedrock/build-tools/reverse_json.py
// reverse_json_offset: 1114112

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
		4'h9: reg_bank_0 <= scratch_in_r;
		default: reg_bank_0 <= "zzzz";
	endcase
end

// Second read cycle
reg [31:0] lb_data_in=0;
always @(posedge clk) if (do_rd_r) begin
	casez (addr_r)
		// Semi-standard address for 2K x 16 configuration ROM
		// xxx800 through xxxfff
		24'b????_????_????_1???_????_????: lb_data_in <= config_rom_out;
		24'h00????: lb_data_in <= mirror_out_0;
		24'h01????: lb_data_in <= ibadge_out;
		24'h02????: lb_data_in <= obadge_out;
		24'h03????: lb_data_in <= rx_mac_data;
		24'h041???: lb_data_in <= rx_counters;
		24'h11????: lb_data_in <= reg_bank_0;
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
reg led_user_r=0;
reg [7:0] led_1_df=0, led_2_df=0;
reg rx_mac_hbank_r=1;
wire local_write = control_strobe & ~control_rd & (addr[23:16]==0);
reg stop_sim=0;  // clearly only useful in simulation
reg [31:0] scratch_out_r=0;  // see cluster_wrap.v
always @(posedge clk) if (local_write) case (addr[3:0])
	1: led_user_r <= data_out;
	2: led_1_df <= data_out;
	3: led_2_df <= data_out;
	4: dbg_rst <= data_out;
	5: rx_mac_hbank_r <= data_out;
	6: stop_sim <= data_out;
	7: scratch_out_r <= data_out;
endcase

// Mirror memory
localparam mirror_aw=5;
dpram #(.aw(mirror_aw),.dw(32)) mirror_0(
	.clka(clk), .addra(addr[mirror_aw-1:0]), .dina(data_out), .wena(local_write),
	.clkb(clk), .addrb(addr[mirror_aw-1:0]), .doutb(mirror_out_0));

// Blink the LEDs with the specified duty factor
// (your eyes won't notice the blink, because it's at 122 kHz)
reg [9:0] led_cc=0;
reg l1=0, l2=0;
always @(posedge clk) begin
	{led_tick, led_cc} <= led_cc+1;  // free-running, no reset
	l1 <= led_cc < {led_1_df, 2'b0};
	l2 <= led_cc < {led_2_df, 2'b0};
end

// Output signal routing
assign scratch_out = scratch_out_r;
assign led_user_mode = led_user_r;
assign led1 = l1;
assign led2 = l2;
wire drive_data_in;
assign data_in = drive_data_in ? lb_data_in : 32'bx;
assign rx_mac_hbank = rx_mac_hbank_r;

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

endmodule
