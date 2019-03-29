// -- Description: Dedicated output register cells for transmitting dual data rate
//                 signals from FPGA. Refer to UG768.
`timescale 1ns / 1ns

// No sign handling here, and the DDR is offset binary.
// So the caller needs to provide offset binary inputs.
module ddr_cells(
	clk,
	data0,
	data1,
	ddr
);

parameter width=16;

input  clk;
input  [width-1:0] data0;
input  [width-1:0] data1;
output [width-1:0] ddr;

wire rst=0;
wire set=0;
wire ce=1;
`ifndef SIMULATE
genvar ix;
generate
    for (ix=0; ix<width; ix=ix+1) begin: out_cell
        ODDR #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
            .INIT(1'b0),
            .SRTYPE("ASYNC")
        ) ODDR_inst(
            .Q(ddr[ix]),
            .C(clk),
            .CE(ce),
            .D1(data0[ix]),
            .D2(data1[ix]),
            .S(set),
            .R(rst)
        );
    end
endgenerate
`else
    reg [width-1:0] r0=0, r1=0, out=0;
    always @(posedge clk) begin
        r0 <= data0;
        r1 <= data1;
    end
    always @(clk) out <= clk ? r1: r0;
    assign ddr = out;
`endif // `ifndef SIMULATE

endmodule
