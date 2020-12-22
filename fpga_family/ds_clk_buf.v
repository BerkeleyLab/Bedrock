module ds_clk_buf #(
   parameter GTX = 0,    // When used to feed a GTX, IBUFDS_GTE2 must be used
   parameter USE_BUF = 0 // 0 - No buffer
                         // 1 - BUFG
                         // 2 - BUFH
)(
   input  clk_p,
   input  clk_n,
   output clk_out
);

   wire clk_out_i;

`ifndef SIMULATE

   generate
      if (GTX == 0) begin
         IBUFDS i_ibufds (
            .O     (clk_out_i),
            .I     (clk_p),
            .IB    (clk_n)
         );
      end else begin
         IBUFDS_GTE2 i_ibufds_gte2 (
            .O     (clk_out_i),
            .ODIV2 (),
            .I     (clk_p),
            .IB    (clk_n),
            .CEB   (1'b0)
         );
      end
   endgenerate
`else
   assign clk_out_i = clk_p;
`endif

   generate
      if (USE_BUF == 0) begin
         assign clk_out = clk_out_i;
      end else if (USE_BUF == 1) begin
         BUFG refclk_buf(
            .O (clk_out),
            .I (clk_out_i)
         );
      end else begin
         BUFH refclk_buf (
            .O (clk_out),
            .I (clk_out_i)
         );
      end
   endgenerate

endmodule
