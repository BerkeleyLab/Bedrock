module lvds_iophy #(parameter flip_d=0)(
input d_p,
input d_n,
output reg [7:0] dout,
input clk_div,
input dco_clk,
output [4:0] idelay_value_out,

input iserdes_reset, // iserdes_reset should be in clk_div/clk_div_out domain
input idelay_ld, // idelay_ld should be in clk_div/clk_div_out domain
input [4:0]idelay_value_in,
input idelay_ce, // idelay enable
input bitslip // bitslip pulse
,output iserdese2_o
,input idelay_inc_int
);

`ifndef SIMULATE
wire data_in_buf; // per-pin-pair ibufds output
wire data_in_delay; // after iodelay
wire Q1,Q2,Q3,Q4,Q5,Q6,Q7,Q8;
IBUFDS #(.DIFF_TERM("TRUE"))
ibufds( .I(flip_d ? d_n : d_p), .IB(flip_d ? d_p : d_n),.O(data_in_buf) );

IDELAYE2 #(.CINVCTRL_SEL("FALSE"),.DELAY_SRC("IDATAIN"),.HIGH_PERFORMANCE_MODE("TRUE"),.IDELAY_TYPE("VAR_LOAD"),.IDELAY_VALUE(0),.REFCLK_FREQUENCY(200.0),.PIPE_SEL("FALSE"),.SIGNAL_PATTERN("DATA"))
idelay_i(
	.DATAIN(1'b0),.REGRST(1'b0),.LDPIPEEN(1'b0),.CINVCTRL(1'b0),
	.CE(idelay_ce),.C(clk_div),.IDATAIN(data_in_buf),.DATAOUT(data_in_delay),.LD(idelay_ld),.INC(idelay_inc_int),.CNTVALUEIN(idelay_value_in),.CNTVALUEOUT(idelay_value_out));

ISERDESE2 #(.DATA_RATE("DDR"),.DATA_WIDTH(8),.INTERFACE_TYPE("NETWORKING"),.DYN_CLKDIV_INV_EN("FALSE"),.DYN_CLK_INV_EN("FALSE"),.NUM_CE(2),.OFB_USED("FALSE"),.IOBDELAY("IFD"),.SERDES_MODE("MASTER"))
serdes_i(.CE1(1'b1),.CE2(1'b1),.CLKDIVP(1'b0),.D(1'b0),.SHIFTIN1(1'b0),.SHIFTIN2(1'b0),.DYNCLKDIVSEL(1'b0),.DYNCLKSEL(1'b0),.OFB(1'b0),.OCLK(1'b0),.OCLKB(1'b0)
,.RST(iserdes_reset),.CLK(dco_clk),.CLKB(~dco_clk),.CLKDIV(clk_div),.DDLY(data_in_delay),
.Q1(Q1),.Q2(Q2),.Q3(Q3),.Q4(Q4),.Q5(Q5),.Q6(Q6),.Q7(Q7),.Q8(Q8),.BITSLIP(bitslip),.O(iserdese2_o),
.SHIFTOUT1(),.SHIFTOUT2()
);
always @ (posedge clk_div) begin
	dout[0]<=flip_d?~Q1:Q1;
	dout[1]<=flip_d?~Q2:Q2;
	dout[2]<=flip_d?~Q3:Q3;
	dout[3]<=flip_d?~Q4:Q4;
	dout[4]<=flip_d?~Q5:Q5;
	dout[5]<=flip_d?~Q6:Q6;
	dout[6]<=flip_d?~Q7:Q7;
	dout[7]<=flip_d?~Q8:Q8;
end
/*assign dout[0]=flip_d?~Q1:Q1;
assign dout[1]=flip_d?~Q2:Q2;
assign dout[2]=flip_d?~Q3:Q3;
assign dout[3]=flip_d?~Q4:Q4;
assign dout[4]=flip_d?~Q5:Q5;
assign dout[5]=flip_d?~Q6:Q6;
assign dout[6]=flip_d?~Q7:Q7;
assign dout[7]=flip_d?~Q8:Q8;
*/
`endif

endmodule
