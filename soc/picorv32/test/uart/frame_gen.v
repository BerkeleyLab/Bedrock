`timescale 1 ns / 1 ns

module frame_gen #(
    parameter [127:0] PATTERN = 128'h0123_3210_2222_3333_4444_5555_beaf_dead,
    parameter DW = 16,
    parameter FRAME_LEN = 28
) (
    input clk,
    input reset,
    input link_up,
    input stream_tx_tready,
    output [DW-1:0] stream_tx_tdata,
    output [1:0] stream_tx_tkeep,
    output stream_tx_tvalid,
    output stream_tx_tlast
);

// Generate frame with 8 words, deassert dvalid every other frame
reg [6:0] mode=0, frame_cnt=0;
reg [128*3-1:0] shift_reg={3{PATTERN}};
wire tlast = mode==FRAME_LEN-1;
always @(posedge clk) begin
    if (reset) begin
        mode <= 0;
        frame_cnt <= 0;
        shift_reg <= {3{PATTERN}};
    end else if (link_up) begin
        mode <= tlast ? 0 : mode + 1'b1;
        if (tlast) frame_cnt <= frame_cnt + 1'b1;
        shift_reg <= {shift_reg[DW-1:0], shift_reg[128*3-1:DW]};
    end
end

wire [DW-1:0] d_in;
wire dvalid;
wire dlast;

assign d_in = shift_reg[DW-1:0];
assign dlast = tlast & dvalid;
assign dvalid = frame_cnt[0];

assign stream_tx_tkeep = 2'b11;
stream_fifo #(
    .DW(DW), .AW(8)
) stream_tx_i (
    .clk        (clk),
    .d_in       (d_in),
    .d_in_valid (dvalid),
    .d_in_last  (dlast),
    .d_in_ready (),
    .d_out_ready(stream_tx_tready),
    .d_out      (stream_tx_tdata),
    .d_out_last (stream_tx_tlast),
    .d_out_valid(stream_tx_tvalid)
);

endmodule

