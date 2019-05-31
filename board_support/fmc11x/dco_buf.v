module dco_buf #(
    parameter BUFR_DIVIDE="4"
) (
    input clk_reset,
    input dco_p,
    input dco_n,
    output clk_div,
    output clk_dco_buf,
    output clk_div_buf
);

wire dco_clk;
IBUFDS #(
    .DIFF_TERM("TRUE")
) ibuf_clk(
    .I      (dco_p),
    .IB     (dco_n),
    .O      (dco_clk)
);

BUFIO bufio_clk (
    .I      (dco_clk),
    .O      (clk_dco_buf)
);

BUFR #(
    .BUFR_DIVIDE(BUFR_DIVIDE),
    .SIM_DEVICE("7SERIES")
) bufr_i(
    .CE     (1'b1),
    .I      (dco_clk),
    .CLR    (clk_reset),
    .O      (clk_div)
);

BUFG bufg_i (
    .I      (clk_div),
    .O      (clk_div_buf)
);

endmodule
