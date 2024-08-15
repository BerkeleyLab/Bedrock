/* A single-channel handshaking consumer for AXI testing */

module channel_consumer #(
  parameter WIDTH = 16
) (
  input  clk,
  input  [WIDTH-1:0] data,
  input  valid,
  // Assert ready_first to make this consumer assert 'ready' before 'valid'
  // otherwise (ready_first=0), waits for 'valid' to assert 'ready'
  input  ready_first,
  output reg ready=1'b0,
  output reg [WIDTH-1:0] data_latched=0,
  output reg data_latched_valid=1'b0
);

always @(posedge clk) begin
  data_latched_valid <= 1'b0;
  if (ready & valid) begin
    ready <= 1'b0;
    data_latched <= data;
    data_latched_valid <= 1'b1;
  end else if (valid | ready_first) begin
    ready <= 1'b1;
  end
end

endmodule
