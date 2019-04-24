module bmb7_comm_clks(
	input clk_in,
	output clk_1x,
	output clk_4x,
	output async_reset
);

wire clk_pll;
BUFG inst_input_clk(.I(clk_in), .O(clk_pll));
parameter reset_duration=12'd200;
reg [11:0] reset_counter=reset_duration;
reg pll_reset=1;
always@(posedge clk_pll) begin
	if (reset_counter==0) pll_reset <= 0;
	else reset_counter <= reset_counter - 1;
end

// PLL from 50 MHz to 200 MHz
`ifdef SIMULATE
parameter chip_family = "SPARTAN 6";
`else
parameter chip_family = "KINTEX 7";
`endif
wire int_clk, int_clk_4x;
wire pll_locked;
pll #(.DEVICE(chip_family), .clkin_period(20.0), .gmult(20),
	.c0div(20),.c1div(5),.c2div(10)) inst_pll (
	.rst(pll_reset),.locked(pll_locked),
	.clkin(clk_pll), .clk0(int_clk), .clk1(int_clk_4x),
	.drp_clk(1'b0),.drp_write(1'b0),.drp_go(1'b0),.drp_addr(7'b0),.drp_data_in(16'b0)
);
BUFGCE inst_clk_bufg(.I(int_clk), .CE(pll_locked), .O(clk_1x));
BUFGCE inst_200mhz_bufg(.I(int_clk_4x), .CE(pll_locked), .O(clk_4x));

reg [3:0] pll_locked_4=0;
always@(posedge clk_1x) begin
	pll_locked_4 <= {pll_locked_4[2:0],pll_locked};
end
assign async_reset = ~(&pll_locked_4);

endmodule
