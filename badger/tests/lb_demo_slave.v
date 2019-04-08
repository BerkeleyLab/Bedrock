// Mostly useless demo of a local bus slave
// just to make it clear that the master is alive (or not)
// Has accreted some self-diagnostic features that (probably) would
// not be part of a final production build.
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
	// Output to hardware
	output led_user_mode,
	output led1,  // PWM
	output led2  // PWM
);

`ifdef SIMULATE
always @(posedge clk) if (control_strobe & ~control_rd) begin
	$display("Localbus write r[%x] = %x", addr, data_out);
end
`endif

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

// Very basic pipelining of two-cycle read process
reg [23:0] addr_r=0;
reg do_rd_r=0;
always @(posedge clk) begin
	do_rd_r <= do_rd;
	addr_r <= addr;
end

// First read cycle
reg [31:0] reg_bank_0=0, dbg_mem_out=0;
always @(posedge clk) if (do_rd) begin
	case (addr[3:0])
		0: reg_bank_0 <= "Hell";
		1: reg_bank_0 <= "o wo";
		2: reg_bank_0 <= "rld!";
		3: reg_bank_0 <= "(::)";
		4: reg_bank_0 <= xdomain_fault_count;
		5: reg_bank_0 <= tx_freq;
		default: reg_bank_0 <= "zzzz";
	endcase
end

// Second read cycle
reg [31:0] lb_data_in=0;
always @(posedge clk) if (do_rd_r) begin
	casex (addr_r)
		24'h01xxxx: lb_data_in <= ibadge_out;
		24'h02xxxx: lb_data_in <= obadge_out;
		24'h11xxxx: lb_data_in <= reg_bank_0;
		default: lb_data_in <= 32'hdeadbeef;
	endcase
end

// Direct writes
reg led_user_r=0;
reg [7:0] led_1_df=0, led_2_df=0;
always @(posedge clk) if (control_strobe) begin
	if (~control_rd) case (addr[3:0])
		1: led_user_r <= data_out;
		2: led_1_df <= data_out;
		3: led_2_df <= data_out;
		4: dbg_rst <= data_out;
	endcase
end
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

endmodule
