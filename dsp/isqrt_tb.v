//
// Copyright 2020, Lawrence Berkeley National Laboratory
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
// contributors may be used to endorse or promote products derived from this
// software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS
// AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
// BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
// TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
///

`timescale 1 ns /  1ns

module isqrt_tb;

parameter X_WIDTH = 24;
parameter Y_WIDTH = (X_WIDTH+1) / 2;

reg  clk = 1'b1;
reg  [X_WIDTH-1:0] arg, x;
reg  en = 0;
wire [Y_WIDTH-1:0] y;
wire dav;
integer pass = 1;

//
// Instantiate the device under test
//
isqrt #(.X_WIDTH(X_WIDTH)) isqrt (.clk(clk),
                                  .x(x),
                                  .en(en),
                                  .y(y),
                                  .dav(dav));

//
// Create a 100 MHz clock
//
always
    #5 clk = ~clk;

initial
begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("isqrt.vcd");
        $dumpvars(0, isqrt_tb);
    end

    #20 ;

    arg = 1;
    while (arg != 0) begin
        verify(arg);
        arg = arg << 1;
    end

    #500 ;

    arg = ~0;
    while (arg != 0) begin
        verify(arg);
        arg = arg >> 1;
    end

    arg = ~0;
    while (arg != 0) begin
        verify(arg);
        arg = arg << 1;
    end

    arg = 3;
    while (arg != 0) begin
        verify(arg);
        arg = arg << 1;
    end

    arg = 3;
    while (arg != 1) begin
        verify(arg);
        arg = ((arg & ~1) << 1) | 1;
    end

    verify(0);
    #300;
    if (!pass) begin
        $display("FAIL");
        $stop();
    end else begin
        $display("PASS");
        $finish();
    end
end

task verify;
    input [X_WIDTH-1:0] arg;
    real actual, diff;
    begin

    @(posedge clk) ;
    @(posedge clk) begin x <= arg; en <= 1; end
    @(posedge clk) begin x <= {X_WIDTH{1'bx}}; en <= 0; end
        while (!dav) @(posedge clk) ;
    actual = $sqrt(arg);
    diff = actual - y;
    if (((arg >    2**53) && ($abs(diff) >    1.0))
     || ((arg <= 2**53) && ($abs(diff) >= 1.0))) begin
        $display($time, " %d %d %.5g    FAILURE", arg, y, diff);
        pass = 0;
     end
     else begin
        $display($time, " %d %d %.5f", arg, y, diff);
    end
    end
endtask

endmodule
