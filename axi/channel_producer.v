/* A single-channel handshaking producer for AXI testing */

module channel_producer #(
  parameter WIDTH = 16
) (
  input  clk,
  output reg [WIDTH-1:0] data=0,
  output reg valid=1'b0,
  input  ready,
  input  [WIDTH-1:0] send_data,
  input  send
);

reg send_0=1'b0;
wire send_re = send & ~send_0;
always @(posedge clk) begin
  send_0 <= send;
  if (send_re) begin
    data <= send_data;
    valid <= 1'b1;
  end
  if (valid & ready) begin
    valid <= 1'b0;
    data <= 0; // Just to make the waveforms clearer
  end
end

endmodule
