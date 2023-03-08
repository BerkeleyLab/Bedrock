`timescale 1ns / 1ns

//
// Simple-minded integer square root
// Result is truncated not rounded
//
// General purpose with the caveat that XWIDTH should be greater than 3.
// (X_WIDTH+1)/2 + 1 cycles per operation, non-pipelined.
// Asserting en when computation is in progress will
// cancel the computation and start another.
//
// With XWIDTH=32, synthesizable to 110 MHz on Spartan3-5.
//
// W. Eric Norum, Lawrence Berkeley National Laboratory
//

module isqrt #(
    parameter X_WIDTH = 32
) (
    input                             clk,
    input               [X_WIDTH-1:0] x,
    input                             en,
    output wire [((X_WIDTH+1)/2)-1:0] y,
    output reg                        dav = 0
);

localparam Y_WIDTH = (X_WIDTH+1) / 2;
wire [X_WIDTH:0] xPad = {1'b0, x};
wire [(2*Y_WIDTH)-1:0] xInit = xPad[(2*Y_WIDTH)-1:0];

reg  [(2*Y_WIDTH)-1:0]  op = 0, pw4 = 0, res = 0;
assign y = res[Y_WIDTH-1:0];

reg busy = 0;

always @(posedge clk)
begin
    if (en) begin
        //
        // op = x  (pad if X_WIDTH is odd)
        // res = 0
        // pw4 = highest power of 4 less than largest X
        //
        op <= xInit;
        res <= 0;
        pw4 <= {2'b01, {Y_WIDTH-1{2'b0}}};
        dav <= 0;
        busy <= 1;
    end else if (busy) begin
        //
        // while (pw4 != 0) {
        //     if (op >= res + pw4) {
        //         op = op - (res + pw4);
        //         res = res +  2 * pw4;
        //     }
        //     res >>= 1;
        //     pw4 >>= 2;
        // }
        //
        if (op >= (res + pw4)) begin
            op <= op - (res + pw4);
            res <= (res >> 1) + pw4;
        end else begin
            res <= (res >> 1);
        end
        pw4 <= (pw4 >> 2);
        if (pw4[0]) begin
            dav <= 1;
            busy <= 0;
        end
    end else begin
        dav <= 0;
    end
end
endmodule
