`timescale 1 ns / 1 ns

module frame_check #(
    parameter [127:0] PATTERN = 128'h0123_3210_2222_3333_4444_5555_beaf_dead,
    parameter DW=16,
    parameter FRAME_LEN = 28
) (
    input clk,
    input reset,
    input [DW-1:0] stream_rx_tdata,
    input stream_rx_tvalid,
    input stream_rx_tlast,
    output stream_rx_tready,
    output reg check_valid
);

initial check_valid = 0;
reg [FRAME_LEN*DW-1:0] shift_reg=0;
wire [DW-1:0] data_rx = stream_rx_tvalid ? stream_rx_tdata: {DW{1'bx}};

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 0;
        check_valid <= 0;
    end else begin
        if (stream_rx_tvalid) shift_reg <= {data_rx, shift_reg[FRAME_LEN*DW-1:DW]};
        if (stream_rx_tlast) check_valid <= (shift_reg == PATTERN);
    end
end

assign stream_rx_tready = 1'b1;
endmodule
