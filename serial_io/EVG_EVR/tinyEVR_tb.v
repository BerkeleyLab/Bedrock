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

`timescale 1ns / 1ns

module tinyEVR_tb;

parameter TIMESTAMP_WIDTH = 64;
parameter ACTION_WIDTH    = 4;
parameter EVSTROBE_COUNT  = 126;

parameter EVCODE_SHIFT_ZERO     = 8'h70;
parameter EVCODE_SHIFT_ONE      = 8'h71;
parameter EVCODE_SECONDS_MARKER = 8'h7D;

reg                    sysClk = 1;
reg                    sysActionWriteEnable = 1'b0;
reg              [7:0] sysActionAddress = {8{1'bx}};
reg [ACTION_WIDTH-1:0] sysActionData = {ACTION_WIDTH{1'bx}};

reg          evrClk = 1;
reg   [15:0] evrRxWord = 16'hx;
reg    [1:0] evrCharIsK = 2'hx;

wire                       ppsMarker, timestampValid;
wire                       ppsMarker_s, timestampValid_s;
wire [TIMESTAMP_WIDTH-1:0] timestamp, timestamp_s;
wire               [EVSTROBE_COUNT:1] evStrobe;
wire    [ACTION_WIDTH-1:0] action;

tinyEVR #(.EVSTROBE_COUNT(EVSTROBE_COUNT))
  tinyEVR (.evrRxClk(evrClk),
           .evrRxWord(evrRxWord),
           .evrCharIsK(evrCharIsK),
           .ppsMarker(ppsMarker),
           .timestampValid(timestampValid),
           .timestamp(timestamp),
           .evStrobe(evStrobe));

smallEVR #(.ACTION_WIDTH(ACTION_WIDTH))
  smallEVR (.evrRxClk(evrClk),
           .evrRxWord(evrRxWord),
           .evrCharIsK(evrCharIsK),
           .ppsMarker(ppsMarker_s),
           .timestampValid(timestampValid_s),
           .timestamp(timestamp_s),
           .action(action),
           .sysClk(sysClk),
           .sysActionWriteEnable(sysActionWriteEnable),
           .sysActionAddress(sysActionAddress),
           .sysActionData(sysActionData));

always begin
    #5 sysClk <= !sysClk;
end
always begin
    #4 evrClk <= !evrClk;
end

integer i;
reg fail=0;
initial
begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("tinyEVR.vcd");
        $dumpvars(0, tinyEVR_tb);
    end

    #40 ;
    for (i = 0 ; i < 256 ; i += 1) begin
        setAction(i, 4'b0000);
    end
    setAction(EVCODE_SECONDS_MARKER, 4'b0010);
    setAction(8'hBC, 4'b1111);
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
    #1000 ;
    if (fail) begin
      $display("FAIL");
      $stop();
    end else begin
      $display("PASS");
      $finish();
    end
end

task setAction;
    input              [7:0] evCode;
    input [ACTION_WIDTH-1:0] evAction;
    begin
    @(posedge sysClk) begin
        sysActionWriteEnable <= 1'b1;
        sysActionAddress <= evCode;
        sysActionData <= evAction;
    end
    @(posedge sysClk) begin
        sysActionWriteEnable <= 1'b0;
        sysActionAddress <= {8{1'bx}};
        sysActionData <= {ACTION_WIDTH{1'bx}};
    end
    end
endtask

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
    @(posedge evrClk) begin
        evrRxWord[7:0] = arg;
        evrCharIsK = 2'bx0;
    end
    @(posedge evrClk) begin
        evrRxWord[7:0] = 8'h00;
        evrCharIsK = 2'bx0;
    end
    @(posedge evrClk) begin
        evrRxWord[7:0] = 8'hBC;
        evrCharIsK = 2'bx1;
    end
    @(posedge evrClk) begin
        evrRxWord[7:0] = 8'h00;
        evrCharIsK = 2'bx0;
    end
    @(posedge evrClk) ;
    end
endtask

task check;
    input [31:0] arg;
    reg [31:0] seconds;
    begin
    seconds = timestamp[32+:32];
    $display("%x %x %s", arg, seconds, (arg == seconds) ? " OK" : "BAD");
    if (arg != seconds) fail = 1;
    end
endtask

endmodule
