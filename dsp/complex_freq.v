`timescale 1ns / 1ns

module complex_freq #(
	parameter refcnt_w = 17
) (
	input clk,  // single clock domain
	input signed [17:0] sdata,
	input sgate,  // high for two cycles representing I and Q
	output signed [refcnt_w-1:0] freq,
	output freq_valid, // Asserted when freq output is valid
	output [16:0] amp_max,
	output [16:0] amp_min,
	output updated, // Asserted when amp_{max,min} are updated
	output timing_err, // New data received while calculation is ongoing
	//
	// Additional output giving magnitude-squared, meant to
	// support average power calculations; can be ignored.
	output [23:0] square_sum_out,
	output square_sum_valid
);

// One multiplier to square the inputs
reg signed [35:0] square, square_d;
reg signed [36:0] square_sum;
always @(posedge clk) begin
	square <= sdata*sdata;
	square_d <= square;
	square_sum <= square + square_d;
end
wire [33:0] square_sum_cut = square_sum[33:0];

// Find cycle of valid sum
reg sgate1, sgate2, sum_valid;
always @(posedge clk) begin
	sgate1 <= sgate;
	sgate2 <= sgate1;
	sum_valid <= sgate1 & sgate2;
end

assign square_sum_out = square_sum_cut[33:10];
assign square_sum_valid = sum_valid;

// Sqrt for convenience and to keep the word width down
wire [16:0] sqrt_val;
wire sqrt_valid;
isqrt #(.X_WIDTH(34)) sqrt(.clk(clk), .x(square_sum_cut), .en(sum_valid),
	.y(sqrt_val), .dav(sqrt_valid));

// Catch obvious errors; leave latching to the upper layers
reg busy=0, timing_err_r=0;
always @(posedge clk) begin
	if (sum_valid) busy <= 1;
	if (sqrt_valid) busy <= 0;
	timing_err_r <= busy & sgate;
end
assign timing_err = timing_err_r;

// Find min and max
wire rollover;
reg [16:0] amp_max_x, amp_min_x;  // developing values
reg [16:0] amp_max_r, amp_min_r;  // frozen values reported to caller
wire cmp_gt = sqrt_val > amp_max_x;
wire cmp_lt = sqrt_val < amp_min_x;
always @(posedge clk) begin
	if (sqrt_valid && (cmp_gt || rollover)) amp_max_x <= sqrt_val;
	if (sqrt_valid && (cmp_lt || rollover)) amp_min_x <= sqrt_val;
	if (sqrt_valid && rollover) begin
		amp_max_r <= amp_max_x;
		amp_min_r <= amp_min_x;
	end
end
assign amp_max = amp_max_r;
assign amp_min = amp_min_r;

// Reference counter
reg [refcnt_w-1:0] refcnt=1;
reg rollover_r=0;
always @(posedge clk) begin
	if (sqrt_valid) refcnt <= refcnt-1;
	rollover_r <= &refcnt;
end
assign rollover = rollover_r;

// Frequency counter
reg [refcnt_w:0] quad_cnt, freq_r;
reg [1:0] quad, oldquad;
wire [1:0] transition = quad - oldquad;
reg invalid=0, freq_valid_r=0;
wire newbit = sdata[17] ^ (sgate1 & quad[0]);
reg updated_r=0;
always @(posedge clk) begin
	if (sgate) quad <= {quad[0], newbit};
	if (sum_valid) begin
		oldquad <= quad;
		case (transition)
		0: quad_cnt <= quad_cnt;
		1: quad_cnt <= quad_cnt-1;
		2: invalid <= 1;
		3: quad_cnt <= quad_cnt+1;
		endcase
	end
	if (sqrt_valid && rollover) begin
		freq_r <= quad_cnt;
		freq_valid_r <= ~invalid;
		quad_cnt <= 0;
		invalid <= 0;
	end
	updated_r <= sqrt_valid && rollover;
end
assign freq = freq_r[refcnt_w:1];
assign freq_valid = freq_valid_r;
assign updated = updated_r;

endmodule
