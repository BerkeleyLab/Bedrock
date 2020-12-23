// Silly little test pattern generator for the four TMDS lanes on an HDMI connector
// When clocked with 250 MHz, will output four 62.5 MHz differential signals
// each with 3/8 duty cycle, and 45 degree static phase shifts between them.
// Set enable to 1 for actual test mode, or to 0 to reduce power and EMI.
module tmds_test(
	input clk,
	input enable,
	output [3:0] tmds_p,
	output [3:0] tmds_n
);

reg enable_r=0;
reg test_a=0, test_b=0, test_c=0, test_d=0;
always @(posedge clk) begin
	enable_r <= enable;  // cross clock domains
	test_a <= ~test_b & enable_r;
	test_b <= test_a;
	test_c <= test_a & ~test_b;
	test_d <= test_c;
end
wire [3:0] tmds_d1 = {test_c, test_b, test_d,  ~test_a};
wire [3:0] tmds_d2 = {test_a, test_c, test_b,   test_d};
wire [3:0] tmds_q;

// Hardware-specific primitives, use unisims or unisims_lrd.
// No need for a generate loop, just use instance arrays.
ODDR #(.DDR_CLK_EDGE ("SAME_EDGE")) ddr[0:3] (
	.Q(tmds_q),
	.C(clk), .CE(1'b1), .R(1'b0), .S(1'b0),
	.D1(tmds_d1), .D2(tmds_d2));

OBUFDS obuf[0:3] (.I(tmds_q), .O(tmds_p), .OB(tmds_n));

endmodule
