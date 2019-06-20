// MIT License
//
// Copyright (c) 2106 Osprey DCS
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

`timescale 1ns/1ns

module tinyEVR_tb;

parameter TIMESTAMP_WIDTH = 64;
parameter EVCODE_SHIFT_ZERO     = 8'h70;
parameter EVCODE_SHIFT_ONE      = 8'h71;
parameter EVCODE_SECONDS_MARKER = 8'h7D;

reg          clk = 1;
reg   [15:0] evrRxWord = 16'hx;
reg    [1:0] evrCharIsK = 2'hx;

wire                       ppsMarker, timestampValid;
wire [TIMESTAMP_WIDTH-1:0] timestamp;
wire               [126:1] evStrobe;

tinyEVR tinyEVR (.evrRxClk(clk),
                 .evrRxWord(evrRxWord),
                 .evrCharIsK(evrCharIsK),
                 .ppsMarker(ppsMarker),
                 .timestampValid(timestampValid),
                 .timestamp(timestamp),
                 .evStrobe(evStrobe));

always begin
    #4 clk <= !clk;
end

integer pass = 1;

initial
begin
    $dumpfile("tinyEVR.lxt");
    $dumpvars(0, tinyEVR_tb);

    #40 ;
    sendEvent(EVCODE_SECONDS_MARKER);
    check(32'h00000000);
    #100 ;
    sendSeconds(32'h12345678);
    #100 ;
    sendEvent(EVCODE_SECONDS_MARKER);
    check(32'h12345678);
    #200 ;
    sendEvent(EVCODE_SECONDS_MARKER);
    check(32'h12345679);
    #200 ;
    sendSeconds(32'h12345678);
    #100 ;
    sendSeconds(32'h12345678);
    #100 ;
    sendEvent(EVCODE_SECONDS_MARKER);
    check(32'h1234567A);
    #1000;
    $display("%s", pass ? "PASS" : "FAIL");
    $finish;
end

task sendSeconds;
    input [31:0] arg;
    begin: sendSec
    integer i;
    for (i = 0 ; i < 32 ; i += 1) begin
        sendEvent(arg[31-i]?  EVCODE_SHIFT_ONE : EVCODE_SHIFT_ZERO);
    end
    end
endtask

task sendEvent;
    input [7:0] arg;
    begin
    @(posedge clk) begin
        evrRxWord[7:0] = arg;
        evrCharIsK = 2'bx0;
    end
    @(posedge clk) begin
        evrRxWord[7:0] = 8'bx;
        evrCharIsK = 2'bx1;
    end
    @(posedge clk) ;
    end
endtask

task check;
    input [31:0] arg;
    reg [31:0] seconds;
    begin
    seconds = timestamp[32+:32];
    $display("%x %x %s", arg, seconds, (arg == seconds) ? "PASS" : "FAIL");
    if (arg != seconds) pass = 0;
    end
endtask

endmodule
