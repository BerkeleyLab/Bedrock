module zest_dac_interp #(
    parameter integer DW=14,
    parameter transparent=0
) (
    input dsp_clk,
    input signed [DW-1:0] din,
    input signed [DW:0] coeff,
    input dac_clk,
    output signed [DW-1:0] dout
);
generate if (transparent) begin : no_cdc
    assign dout = din;
end else begin : add_cdc
    // input is: s0, s1, s2, ...
    // dac_clk is 2x of dsp_clk, phase aligned
    wire signed [DW-1:0] d1;
    data_xdomain #(.size(DW)) data_xdomain (
        .clk_in         (dsp_clk),
        .gate_in        (1'b1),
        .data_in        (din),
        .clk_out        (dac_clk),
        .gate_out       (),
        .data_out       (d1)
    );

    reg signed [DW-1:0] d2=0, d3=0;
    reg tick=0;
    always @(posedge dac_clk) begin
        tick <= ~tick;
        d2 <= d1;
        d3 <= d2;
    end

    wire signed [DW:0] sum = d2 + d1;
    reg signed [2*DW+1:0] r=0;
    wire signed [2*DW+1:0] r1 = r >>> DW;
    reg signed [DW-1:0] dout_r=0;
    always @(posedge dac_clk) begin
        r <= sum * coeff;
        // output is: s0, (s0+s1)/2*coeff, s1, (s1+s2)/2*coeff, s2, ...
        dout_r <= ~tick ? r1[DW-1:0] : d3;
    end
    assign dout = dout_r;
end endgenerate

endmodule
