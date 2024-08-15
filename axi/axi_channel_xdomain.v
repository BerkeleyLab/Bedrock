/* Transfer data 'dataa' from clock domain 'clka' to domain 'clkb' by streatching
 * the AXI handshake signals between 'valid' ('clka' domain) and 'ready' ('clkb' domain).
 * This works for all clock ratios, but could be optimized for a given ratio by simply
 * stretching pulses as required.  By quasi-Monte-Carlo methods, this stretched handshake
 * circuit adds an average of 4 cycles to each transaction (cycles being measured relative
 * to the slower clock) which translates to a roughly 50% performance penalty compared to
 * the single-domain solution.
 */

module axi_channel_xdomain #(
  parameter WIDTH = 16
) (
  input  clka,
  input  [WIDTH-1:0] dataa,
  input  valida,
  output readya,
  input  clkb,
  output [WIDTH-1:0] datab,
  output validb,
  input  readyb
);

localparam DEPTH = 2;

(* ASYNC_REG="TRUE", magic_cdc *) reg [DEPTH-1:0] x_ready=0;
reg a_ready=1'b0;
assign readya = a_ready;
reg a_valid=1'b0;
reg [WIDTH-1:0] a_data=0;
always @(posedge clka) begin
  x_ready <= {x_ready[DEPTH-2:0], readyb};
  a_ready <= x_ready[DEPTH-1];
  if (valida) begin
    a_data <= dataa;
    a_valid <= 1'b1;
  end else if (x_valid[0]) begin // Don't deassert until latched in 'clkb' domain
    a_valid <= 1'b0;
  end
end

(* ASYNC_REG="TRUE", magic_cdc *) reg [DEPTH-1:0] x_valid=0;
(* ASYNC_REG="TRUE", magic_cdc *) reg [WIDTH-1:0] x_data [0:DEPTH-1];
reg b_valid=1'b0;
reg valid_mask=1'b1;
assign validb = b_valid & valid_mask;
reg [WIDTH-1:0] b_data=0;
assign datab = b_data;
integer N;
always @(posedge clkb) begin
  x_valid <= {x_valid[DEPTH-2:0], a_valid};
  x_data[0] <= a_data;
  for (N = 1; N < DEPTH; N = N + 1) begin
    x_data[N] <= x_data[N-1];
  end
  b_valid <= x_valid[DEPTH-1];
  b_data <= x_data[DEPTH-1];
  if (b_valid & readyb) begin
    valid_mask <= 1'b0;
  end
  // Look for falling edge of 'valida' (crossed to 'clkb' domain)
  if (b_valid & ~x_valid[DEPTH-1]) begin
    // Re-enable valid mask
    valid_mask <= 1'b1;
  end
end

/* Handshake Rules:
 *  'valid' asserted means 'dataa' is valid
 *  'dataa' must remain valid until 'readya' is asserted
 *  so if we delay 'readya' by one extra cycle in the 'clkb'
 *  domain, we can't miss a "too short" pulse (unless the rules
 *  are violated).
 */
endmodule
