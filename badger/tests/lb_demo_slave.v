// Mostly useless demo of a local bus slave
// just to make it clear that the master is alive (or not)
// Has accreted some self-diagnostic features that (probably) would
// not be part of a final production build.
// Only write addresses implemented are LEDs, addr[23:20]==0.
module lb_demo_slave(
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
	// Features
	input tx_mac_done,
	input [15:0] rx_mac_data,
	input [1:0] rx_mac_buf_status,
	output rx_mac_hbank,
	// Output to hardware
	output led_user_mode,
	output led1,  // PWM
	output led2  // PWM
);

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
fake_config_romx rom(
	.clk(clk), .address(addr[10:0]), .data(config_rom_out)
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
		4'h6: reg_bank_0 <= tx_mac_done;
		4'h7: reg_bank_0 <= rx_mac_buf_status;
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
		24'h00000?: lb_data_in <= reg_bank_0;
		24'h01????: lb_data_in <= ibadge_out;
		24'h02????: lb_data_in <= obadge_out;
		24'h03????: lb_data_in <= rx_mac_data;
		24'h11????: lb_data_in <= reg_bank_0;
		default: lb_data_in <= 32'hdeadbeef;
	endcase
end

// Direct writes
reg led_user_r=0;
reg [7:0] led_1_df=0, led_2_df=0;
reg rx_mac_hbank_r=1;
wire led_write = control_strobe & ~control_rd & (addr[23:20]==0);
reg stop_sim=0;  // clearly only useful in simulation
always @(posedge clk) if (led_write) case (addr[3:0])
	1: led_user_r <= data_out;
	2: led_1_df <= data_out;
	3: led_2_df <= data_out;
	4: dbg_rst <= data_out;
	5: rx_mac_hbank_r <= data_out;
	6: stop_sim <= data_out;
endcase
// Blink the LEDs with the specified duty factor
// (your eyes won't notice the blink, because it's at 488 kHz)
reg [9:0] led_cc=0;
reg l1=0, l2=0;
always @(posedge clk) begin
	led_cc <= led_cc+1;  // free-running, no reset
	l1 <= led_cc < {led_1_df, 2'b0};
	l2 <= led_cc < {led_2_df, 2'b0};
end
assign led_user_mode = led_user_r;
assign led1 = l1;
assign led2 = l2;
assign data_in = lb_data_in;
assign rx_mac_hbank = rx_mac_hbank_r;

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
