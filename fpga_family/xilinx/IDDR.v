// trivial substitute for xilinx unisim models
// for more info refer to
// https://docs.amd.com/go/en-US/ug471_7Series_SelectIO

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
// verilator lint_restore
reg [1:0] r1;
always @(posedge C) begin
    r[0] <= D;
    r1   <= r;
end
always @(negedge C) r[1] <= D;

assign {Q2, Q1} = r1;

endmodule
