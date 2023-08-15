module lmk01801 #(parameter flip_clk=0, parameter SPIMODE="passthrough") (
   input CLKOUT3_INV,
   input CLKOUT3,
   output CLKUWIRE,
   output DATAUWIRE,
   output LEUWIRE,
   input DATAUWIRE_IN,
   output clkout,
   input clkuwire_in,
   input datauwire_inout,
   input leuwire_in,
   output datauwire_in
);

generate
if (SPIMODE=="passthrough")begin: passthrough
   assign CLKUWIRE  = clkuwire_in;
   assign LEUWIRE   = leuwire_in;
   assign DATAUWIRE = datauwire_inout;
   assign datauwire_in = DATAUWIRE_IN;
end
endgenerate

wire clk_n = CLKOUT3_INV;
wire clk_p = CLKOUT3;
wire clk_ibufgds;

`ifndef SIMULATE
IBUFDS #(.DIFF_TERM("TRUE")) ibuf_clk (
   .I  (flip_clk ? clk_n : clk_p),
   .IB (flip_clk? clk_p : clk_n),
   .O  (clk_ibufgds));

BUFG bufg_i (.I(clk_ibufgds), .O(clkout));
`endif
endmodule
