module gmii_gtp #(
    parameter dw = 10
)
(
    // gmii side
    input gmii_tx_clk,
    input gmii_rx_clk,
    input [dw-1:0] gmii_txd,
    output reg [dw-1:0] gmii_rxd,
    // gtp side
    input gtp_tx_clk,
    //input gtp_rx_clk,
    output reg [2*dw-1:0] gtp_txd,
    input [2*dw-1:0] gtp_rxd
);

reg [dw-1:0] gmii_txd_d;
wire [dw-1:0] gtp_rxd_l = gtp_rxd[dw-1:0];
wire [dw-1:0] gtp_rxd_m = gtp_rxd[2*dw-1:dw];
reg even=0;

// decode incoming data @ gtp_tx_clk
always @(posedge gmii_tx_clk) begin
    gmii_txd_d <= gmii_txd;
end

always @(posedge gmii_rx_clk) begin
    even <= ~even;
    gmii_rxd <= even ? gtp_rxd_l : gtp_rxd_m;
end

// encode outgoing data @ gmii_tx_clk
always @(posedge gtp_tx_clk) begin
    gtp_txd <= {gmii_txd, gmii_txd_d};
end

endmodule
