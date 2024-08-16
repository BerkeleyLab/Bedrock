/* Transfer data 'dataa' from clock domain 'clka' to domain 'clkb' by streatching
 * the AXI handshake signals between 'valid' ('clka' domain) and 'ready' ('clkb' domain).
 * This works for all clock ratios, but could be optimized for a given ratio by simply
 * stretching pulses as required.  By quasi-Monte-Carlo methods, this stretched handshake
 * circuit adds an average of 4 cycles to each transaction (cycles being measured relative
 * to the slower clock) which translates to a roughly 50% performance penalty compared to
 * the single-domain solution.
 */

module axi_channel_xdomain #(
  parameter WIDTH = 16,
  // If FIFO_AW == 0, stretches handshake signals across the clock boundary,
  // guaranteeing the transaction at the cost of additional cycles delay
  // Else, uses best effort (FIFO-based) transactions, which could
  // overflow.
  parameter FIFO_AW = 0
) (
  input  clka,
  input  [WIDTH-1:0] dataa,
  input  valida,
  output readya,
  input  clkb,
  output [WIDTH-1:0] datab,
  output validb,
  input  readyb,
  input  enb
);

localparam DEPTH = 2;
reg b_valid=1'b0;
assign validb = b_valid & valid_mask;
reg valid_mask=1'b1;
reg [WIDTH-1:0] b_data=0;
assign datab = b_data;
generate
  if (FIFO_AW == 0) begin: stretch
    /* Handshake Rules:
     *  'valid' asserted means 'dataa' is valid
     *  'dataa' must remain valid until 'readya' is asserted
     *  so if we delay 'readya' by one extra cycle in the 'clkb'
     *  domain, we can't miss a "too short" pulse (unless the rules
     *  are violated).
     */
    reg a_ready=1'b0;
    assign readya = a_ready;
    (* ASYNC_REG="TRUE", magic_cdc *) reg [DEPTH-1:0] x_ready=0;
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
  end else begin: best_effort
    wire full;
    // clka domain
    assign readya = ~full;
    reg valida_r=1'b0;
    //reg valida_stb=1'b0;
    always @(posedge clka) begin
      valida_r <= valida;
      //valida_stb <= valida & ~valida_r;
    end
    wire valida_stb = valida & ~valida_r;
    // clkb domain
    wire empty;
    // fifo_2c is a bit weird.  When 're' is strobed, the read pointer
    // increments (1 cycle delay), then 'dout' is asserted according to the
    // new read pointer on the next cycle (1 more cycle delay).  So I need
    // to wait an additional cycle after strobing 're'.
    reg b_read=1'b0, b_read_wait=1'b0;
    wire [WIDTH-1:0] next_datab;
    always @(posedge clkb) begin
      b_read <= 1'b0;
      b_read_wait <= b_read;
      if (~empty & ~b_valid & ~b_read_wait & enb) begin
        b_valid <= 1'b1;
        b_read <= 1'b1;
        b_data <= next_datab;
      end
      if (b_valid & readyb) begin
        b_valid <= 1'b0;
      end
    end
    fifo_2c #(
      .aw(FIFO_AW),
      .dw(WIDTH)
    ) fifo_2c_i (
      .wr_clk     (clka), // input
      .we         (valida_stb), // input
      .din        (dataa), // input [dw-1:0]
      .wr_count   (), // output [aw:0]
      .full       (full), // output
      .rd_clk     (clkb), // input
      .re         (b_read), // input
      .dout       (next_datab), // output [dw-1:0]
      .rd_count   (), // output [aw:0]
      .empty      (empty) // output
    );
  end
endgenerate


endmodule
