`timescale 1ns / 1ns

//
// Simple-minded integer square root
//
// General purpose with the caveat that XWIDTH should be even.
// X_WIDTH/2 + 1 cycles per operation, non-pipelined.
// Setting en when computation is in progress will
// cancel the computation and start another.
//
// With XWIDTH=32, synthesizable to 110 MHz on Spartan3-5.
//
// Eric Norum
// LBNL
//

module isqrt #(
	parameter X_WIDTH     = 32,
	parameter Y_WIDTH     = X_WIDTH / 2
) (
	input                 clk,
	input  [X_WIDTH-1:0]  x,
	input                 en,
	output [Y_WIDTH-1:0]  y,
	output reg            dav
);

reg  [X_WIDTH-1:0]  op = 0, pw4 = 0, res = 0;
initial  dav = 0;

assign y = res[Y_WIDTH-1:0];

always @(posedge clk)
begin
    if (en) begin
        //
        //  op = x
        // res = 0
        // pw4 = highest power of 4 less than largest X
        //
        op <= x;
        res <= 0;
        pw4 <= {1'b1 ,{Y_WIDTH-1{2'b0}}};
        dav <= 0;
    end else begin
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
        if (pw4 != 0) begin
            if (op >= (res + pw4)) begin
                op <= op - (res + pw4);
                res <= (res >> 1) + pw4;
            end else begin
                res <= (res >> 1);
            end
            pw4 <= (pw4 >> 2);
        end
        if (pw4 == 1) begin
            dav <= 1;
        end else begin
            dav <= 0;
        end
    end
end
endmodule
