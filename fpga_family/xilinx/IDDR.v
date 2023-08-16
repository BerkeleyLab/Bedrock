// trivial substitute for xilinx unisim models
// for more info refer to
// https://www.xilinx.com/support/documentation/user_guides/ug471_7Series_SelectIO.pdf

module IDDR #(
    parameter DDR_CLK_EDGE="SAME_EDGE_PIPELINED"
) (
    output Q1,
    output Q2,
    input C,
    input CE,
    input D,
    input R,
    input S
);

initial begin
    if (DDR_CLK_EDGE != "SAME_EDGE_PIPELINED") begin
        $display("Only DDR_CLK_EDGE == SAME_EDGE_PIPELINED supported right now.");
        $finish;
    end
end

// verilator lint_save
// verilator lint_off MULTIDRIVEN
reg [1:0] r;
reg [1:0] r1;
always @(posedge C) begin
    r[0] <= D;
    r1   <= r;
end
always @(negedge C) r[1] <= D;
// verilator lint_restore

assign {Q2, Q1} = r1;

endmodule
