module ds_clk_buf #(
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
   IBUFDS i_ibufds (
      .O     (clk_out_i),
      .I     (clk_p),
      .IB    (clk_n)
   );
`else
   assign clk_out = clk_p;
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
