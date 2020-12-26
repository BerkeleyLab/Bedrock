
module uart_stream #(
    parameter [31:0] DW=8,
    parameter [31:0] AW_TX=8,
    parameter [31:0] AW_RX=8
) (
    // control interface
    input           clk,
    input           rst,
    input  [15:0]   uprescale,
    output [3:0]    uart_status,

    // Data interface
    input  [DW-1:0] utx_tdata,
    input           utx_tvalid,
    input           utx_tlast,
    output          utx_tready,

    output [DW-1:0] urx_tdata,
    output          urx_tvalid,
    output          urx_tlast,
    input           urx_tready,

    // Physical interface
    output          txd,
    input           rxd
);

    wire s_tx_tready, s_tx_tvalid;
    wire s_tx_tlast;
    wire [DW-1:0] s_tx_tdata;

    wire tx_fifo_empty;
    stream_fifo #(
        .DW(DW), .AW(AW_TX)
    ) tx_fifo (
        .clk        (clk        ),
        .d_in       (utx_tdata  ),
        .d_in_valid (utx_tvalid ),
        .d_in_last  (utx_tlast  ),
        .d_in_ready (utx_tready ),
        .d_out      (s_tx_tdata ),
        .d_out_valid(s_tx_tvalid),
        .d_out_last (s_tx_tlast ),
        .d_out_ready(s_tx_tready),
        .fifo_empty (tx_fifo_empty)
    );

    // physical
    wire tx_busy;
    uart_tx #(
        .DATA_WIDTH(DW)
    ) uart_tx_inst (
        .clk                (clk        ),
        .rst                (rst        ),
        .input_axis_tdata   (s_tx_tdata ),
        .input_axis_tvalid  (s_tx_tvalid),
        .output_axis_tready (s_tx_tready),
        .txd                (txd        ),
        .busy               (tx_busy    ),
        .prescale           (uprescale  )
    );

    wire s_rx_tready, s_rx_tvalid;
    wire [DW-1:0] s_rx_tdata;

    // physical
    wire rx_busy;
    wire frame_error;
    wire overrun_error;
    uart_rx #(
        .DATA_WIDTH(DW)
    ) uart_rx_inst (
        .clk                (clk        ),
        .rst                (rst        ),
        .output_axis_tdata  (s_rx_tdata ),
        .output_axis_tvalid (s_rx_tvalid),
        .input_axis_tready (s_rx_tready),
        .rxd                (rxd        ),
        .busy               (rx_busy    ),
        .overrun_error      (overrun_error),
        .frame_error        (frame_error ),
        .prescale           (uprescale  )
    );

    wire rx_fifo_empty;
    assign uart_status = {frame_error, overrun_error, rx_busy || !rx_fifo_empty, tx_busy || !tx_fifo_empty};

    stream_fifo #(
        .DW(DW), .AW(AW_RX)
    ) rx_fifo (
        .clk        (clk        ),
        .d_in       (s_rx_tdata ),
        .d_in_valid (s_rx_tvalid),
        .d_in_last  (1'b1       ),
        .d_in_ready (s_rx_tready),
        .d_out      (urx_tdata  ),
        .d_out_valid(urx_tvalid ),
        .d_out_last (urx_tlast  ),
        .d_out_ready(urx_tready ),
        .fifo_empty (rx_fifo_empty)
    );
endmodule
