module lvds_dco #(parameter flip_dco=0) (
input clk_reset,  // for resetting BUFR divider state
input mmcm_reset,  // be safe
output mmcm_locked,
input dco_p,
input dco_n,
output clk_div_bufg, // clock aligned with dout
output clk_div_bufr,
output dco_clk_out,
input mmcm_psclk,
input mmcm_psen,
input mmcm_psincdec,
output mmcm_psdone
);

`ifndef SIMULATE

wire dco_clk, dco_clk_buf,frame;
IBUFGDS #(.DIFF_TERM("TRUE")) ibuf_clk(.I(flip_dco ? dco_n : dco_p), .IB(flip_dco? dco_p : dco_n), .O(dco_clk));
//IBUFDS #(.DIFF_TERM("TRUE")) ibufds_frame(.I(flip_frame ? frame_n : frame_p), .IB(flip_frame ? frame_p : frame_n), .O(frame));
BUFIO bufio_clk(.I(dco_clk), .O(dco_clk_buf));
assign dco_clk_out = dco_clk_buf;
// Now divide dco_clk by four to get clk_div
BUFR #(.BUFR_DIVIDE("4"), .SIM_DEVICE("7SERIES"))
bufr_i(.CE(1'b1), .I(dco_clk), .CLR(clk_reset),.O(clk_div_bufr));

// MMCM for clock deskew
wire clk_div_to_bufg;
`define USE_MMCM
`ifdef USE_MMCM
wire mmcm_fdbk_out, mmcm_fdbk_in;
MMCME2_ADV #(
	.CLKIN1_PERIOD(10.6),
	.CLKOUT0_USE_FINE_PS("TRUE"),
	.CLKFBOUT_MULT_F(10), .CLKOUT0_DIVIDE_F(10)  // VCO = 1320/14*10 = 943 MHz?
	) mmcm(
	.CLKIN1(clk_div_bufr), .CLKOUT0(clk_div_to_bufg),
	.CLKFBOUT(mmcm_fdbk_out), .CLKFBIN(mmcm_fdbk_in),
	.RST(mmcm_reset), .PWRDWN(1'b0),
	.LOCKED(mmcm_locked),
	.CLKIN2(1'b0), .CLKINSEL(1'b1),
	.DADDR(7'b0), .DI(16'b0), .DWE(1'b0), .DEN(1'b0), .DCLK(1'b0),
	.PSCLK(mmcm_psclk), .PSEN(mmcm_psen),
	.PSINCDEC(mmcm_psincdec), .PSDONE(mmcm_psdone)
);
BUFG bufg_fdbk(.I(mmcm_fdbk_out), .O(mmcm_fdbk_in));
`else
assign clk_div_to_bufg = clk_div_bufr;
`endif

BUFG bufg_i(.I(clk_div_to_bufg), .O(clk_div_bufg));
`endif
endmodule
