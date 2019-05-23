module badge_trace(
	// Diagnostic input
	input badge_clk,
	input badge_stb,
	input [7:0] badge_data,
	// Arbitrary domain
	input trace_reset,
	// Local bus side
	input lb_clk,
	input [23:0] lb_addr,
	input lb_rd,
	output [7:0] lb_result
);

// Time since boot, wrap every 34.4 seconds
// runs in badge_clk domain so it can be written along with the badge
reg [31:0] tick_counter=0;  // 32'h03ffffc0;
always @(posedge badge_clk) tick_counter <= tick_counter+1;

reg [31:0] time_sr=0;
reg badge_stb_r=0;
reg [7:0] badge_stb_chain=0;
wire first_stb = badge_stb & ~(|badge_stb_chain[7:0]);
wire times_stb = |badge_stb_chain[6:3];
always @(posedge badge_clk) begin
	badge_stb_chain <= {badge_stb_chain[6:0], first_stb};
	if (first_stb) time_sr <= tick_counter;
	if (times_stb) time_sr <= {time_sr[23:0], 8'b0};
end

// Debug trace memory
parameter daw=12;  // debug address width
reg dbg_rst=0;
reg [daw-1:0] badge_cnt=0;
reg [7:0] dbg_mem[0:(1<<daw)-1];
reg trace_reset_r=0;  // 1-bit absorb into badge_clk domain
wire [7:0] write_data = times_stb ? time_sr[31:24] : badge_data;
always @(posedge badge_clk) begin
	trace_reset_r <= trace_reset;
	if (trace_reset_r) badge_cnt <= 0;
	if (badge_stb | times_stb) begin
		dbg_mem[badge_cnt] <= write_data;
		// once memory is filled up, stop
		if (~(&badge_cnt)) badge_cnt <= badge_cnt+1;
	end
end

// Readout of memory plane
reg [7:0] result_r=0;
always @(posedge lb_clk) if (lb_rd)
	result_r <= dbg_mem[lb_addr[daw-1:0]];
assign lb_result = result_r;

endmodule
