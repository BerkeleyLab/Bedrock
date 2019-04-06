module gtxclks(
input REFCLK_P
,input REFCLK_N
,output gtrefclk
,output gtrefclkbuf
);

`ifndef SIMULATE
IBUFDS_GTE2 ibufds_instQ0_CLK1(.O(gtrefclk),.ODIV2(),.CEB(1'b0),.I(REFCLK_P),.IB(REFCLK_N));
// Instantiate a MMCM module to divide the reference clock. Uses internal feedback
// for improved jitter performance, and to avoid consuming an additional BUFG
`else
assign gtrefclk = REFCLK_P;
`endif

parameter   USE_BUFG = 0; // set to 1 if you want to use BUFG for cpll railing logic
//  wire    refclk;
generate
 if(USE_BUFG == 1)
 begin
  BUFG refclk_buf(.O   (gtrefclkbuf),   .I   (gtrefclk));
 end

 else
 begin
  BUFH refclk_buf (.O   (gtrefclkbuf),   .I   (gtrefclk));
 end
endgenerate
endmodule
