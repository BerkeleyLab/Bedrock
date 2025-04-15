// MIT License
//
// Copyright (c) 2016 Osprey DCS
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

////////////////////////////////////////////////////////////////////////////////
// Very small subset of MRF event receiver
// Provides time stamps, event strobes and some status markers.
module tinyEVR #(
    parameter EVSTROBE_COUNT   = 126,
    parameter DEBUG            = "false",
    parameter NOMINAL_CLK_RATE = 125_000_000,
    parameter STATUS_COUNTER_WIDTH = 10,
    parameter TIMESTAMP_WIDTH  = 64
    ) (
    input  wire                                            evrRxClk,

    (*mark_debug=DEBUG*) input                      [15:0] evrRxWord,
    (*mark_debug=DEBUG*) input                       [1:0] evrCharIsK,

    // Status counters for time-of-day
    (*mark_debug=DEBUG*) output wire [STATUS_COUNTER_WIDTH-1:0] tooManyBitsCounter,
    (*mark_debug=DEBUG*) output wire [STATUS_COUNTER_WIDTH-1:0] tooFewBitsCounter,
    (*mark_debug=DEBUG*) output wire [STATUS_COUNTER_WIDTH-1:0] outOfSeqCounter,

    (*mark_debug=DEBUG*) output wire                       ppsMarker,
    (*mark_debug=DEBUG*) output wire                       timestampValid,
    (*mark_debug=DEBUG*) output wire [TIMESTAMP_WIDTH-1:0] timestamp,
    (*mark_debug=DEBUG*) output wire                       timestampHAValid,
    (*mark_debug=DEBUG*) output wire [TIMESTAMP_WIDTH-1:0] timestampHA,
    (*mark_debug=DEBUG*) output wire                 [7:0] distributedDataBus,
    output wire [EVSTROBE_COUNT:1]                         evStrobe);

tinyEVRcommon #(.ACTION_RAM_WIDTH(0),
                .EVSTROBE_COUNT(EVSTROBE_COUNT),
                .DEBUG(DEBUG),
                .NOMINAL_CLK_RATE(NOMINAL_CLK_RATE),
                .STATUS_COUNTER_WIDTH(STATUS_COUNTER_WIDTH),
                .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH))
  tinyEVRcommon (
    .evrRxClk(evrRxClk),
    .evrRxWord(evrRxWord),
    .evrCharIsK(evrCharIsK),
    .ppsMarker(ppsMarker),
    .timestampValid(timestampValid),
    .timestamp(timestamp),
    .timestampHAValid(timestampHAValid),
    .timestampHA(timestampHA),
    .distributedDataBus(distributedDataBus),
    .action(evStrobe),
    .tooManyBitsCounter(tooManyBitsCounter),
    .tooFewBitsCounter(tooFewBitsCounter),
    .outOfSeqCounter(outOfSeqCounter),
    .sysClk(1'b0),
    .sysActionWriteEnable(1'b0),
    .sysActionAddress(8'h00),
    .sysActionData(1'b0));
endmodule

////////////////////////////////////////////////////////////////////////////////
// Somewhat larger subset of MRF event receiver
// Based on more conventional lookup table
module smallEVR #(
    parameter ACTION_WIDTH    = 1,
    parameter DEBUG           = "false",
    parameter NOMINAL_CLK_RATE = 125_000_000,
    parameter STATUS_COUNTER_WIDTH = 10,
    parameter TIMESTAMP_WIDTH = 64
    ) (
    input  wire                                            evrRxClk,

    (*mark_debug=DEBUG*) input                      [15:0] evrRxWord,
    (*mark_debug=DEBUG*) input                       [1:0] evrCharIsK,

    // Status counters for time-of-day
    (*mark_debug=DEBUG*) output wire [STATUS_COUNTER_WIDTH-1:0] tooManyBitsCounter,
    (*mark_debug=DEBUG*) output wire [STATUS_COUNTER_WIDTH-1:0] tooFewBitsCounter,
    (*mark_debug=DEBUG*) output wire [STATUS_COUNTER_WIDTH-1:0] outOfSeqCounter,

    (*mark_debug=DEBUG*) output wire                       ppsMarker,
    (*mark_debug=DEBUG*) output wire                       timestampValid,
    (*mark_debug=DEBUG*) output wire [TIMESTAMP_WIDTH-1:0] timestamp,
    (*mark_debug=DEBUG*) output wire                       timestampHAValid,
    (*mark_debug=DEBUG*) output wire [TIMESTAMP_WIDTH-1:0] timestampHA,
    (*mark_debug=DEBUG*) output wire                 [7:0] distributedDataBus,
    (*mark_debug=DEBUG*) output wire    [ACTION_WIDTH-1:0] action,

    input                    sysClk,
    input                    sysActionWriteEnable,
    input              [7:0] sysActionAddress,
    input [ACTION_WIDTH-1:0] sysActionData);

tinyEVRcommon #(.ACTION_RAM_WIDTH(ACTION_WIDTH),
                .EVSTROBE_COUNT(0),
                .DEBUG(DEBUG),
                .NOMINAL_CLK_RATE(NOMINAL_CLK_RATE),
                .STATUS_COUNTER_WIDTH(STATUS_COUNTER_WIDTH),
                .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH))
  tinyEVRcommon (
    .evrRxClk(evrRxClk),
    .evrRxWord(evrRxWord),
    .evrCharIsK(evrCharIsK),
    .ppsMarker(ppsMarker),
    .timestampValid(timestampValid),
    .timestamp(timestamp),
    .timestampHAValid(timestampHAValid),
    .timestampHA(timestampHA),
    .distributedDataBus(distributedDataBus),
    .action(action),
    .tooManyBitsCounter(tooManyBitsCounter),
    .tooFewBitsCounter(tooFewBitsCounter),
    .outOfSeqCounter(outOfSeqCounter),
    .sysClk(sysClk),
    .sysActionWriteEnable(sysActionWriteEnable),
    .sysActionAddress(sysActionAddress),
    .sysActionData(sysActionData));
endmodule

////////////////////////////////////////////////////////////////////////////////
// Common implementation
module tinyEVRcommon #(
    parameter ACTION_RAM_WIDTH = 0,
    parameter EVSTROBE_COUNT   = 126,
    parameter DEBUG            = "false",
    parameter TIMESTAMP_WIDTH  = 64,
    parameter NOMINAL_CLK_RATE = 125_000_000,
    parameter STATUS_COUNTER_WIDTH = 10,
    parameter ACT_MSB = ACTION_RAM_WIDTH?ACTION_RAM_WIDTH-1:EVSTROBE_COUNT,
    parameter ACT_LSB = ACTION_RAM_WIDTH?0:1
    ) (
    input  wire                                            evrRxClk,

    (*mark_debug=DEBUG*) input                      [15:0] evrRxWord,
    (*mark_debug=DEBUG*) input                       [1:0] evrCharIsK,

    (*mark_debug=DEBUG*) output wire                       ppsMarker,
    (*mark_debug=DEBUG*) output wire                       timestampValid,
    (*mark_debug=DEBUG*) output wire [TIMESTAMP_WIDTH-1:0] timestamp,
    (*mark_debug=DEBUG*) output wire                       timestampHAValid,
    (*mark_debug=DEBUG*) output wire [TIMESTAMP_WIDTH-1:0] timestampHA,
    (*mark_debug=DEBUG*) output wire                 [7:0] distributedDataBus,
    output wire [ACT_MSB:ACT_LSB]                          action,

    // Status counters for time-of-day
    output wire [STATUS_COUNTER_WIDTH-1:0] tooManyBitsCounter,
    output wire [STATUS_COUNTER_WIDTH-1:0] tooFewBitsCounter,
    output wire [STATUS_COUNTER_WIDTH-1:0] outOfSeqCounter,

    input                                             sysClk,
    input                                             sysActionWriteEnable,
    input                                       [7:0] sysActionAddress,
    input [(ACTION_RAM_WIDTH?ACTION_RAM_WIDTH-1:0):0] sysActionData);

localparam SECONDS_WIDTH = TIMESTAMP_WIDTH/2;
localparam TICKS_WIDTH   = TIMESTAMP_WIDTH/2;
reg [SECONDS_WIDTH-1:0] tsSeconds = 0;
reg   [TICKS_WIDTH-1:0] tsTicks = 0;

localparam EVCODE_SHIFT_ZERO     = 8'h70;
localparam EVCODE_SHIFT_ONE      = 8'h71;
localparam EVCODE_SECONDS_MARKER = 8'h7D;

(*mark_debug=DEBUG*) reg           [SECONDS_WIDTH-1:0] shiftReg;
(*mark_debug=DEBUG*) reg [$clog2(SECONDS_WIDTH)-1:0] bitsLeft = SECONDS_WIDTH - 1;
(*mark_debug=DEBUG*) reg enoughBits = 0, tooManyBits = 0;

wire [7:0] evCode = evrRxWord[7:0];
assign distributedDataBus = evrRxWord[15:8];
wire evCodeValid = !evrCharIsK[0];

todReceiver #(
    .NOMINAL_CLK_RATE(NOMINAL_CLK_RATE),
    .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
    .EVCODE_SHIFT_ZERO(EVCODE_SHIFT_ZERO),
    .EVCODE_SHIFT_ONE(EVCODE_SHIFT_ONE),
    .EVCODE_SECONDS_MARKER(EVCODE_SECONDS_MARKER),
    .STATUS_COUNTER_WIDTH(STATUS_COUNTER_WIDTH))
  todReceiver (
    .clk(evrRxClk),
    .rst(1'b0),

    .evCode(evCode),
    .evCodeValid(evCodeValid),

    .tooManyBitsCounter(tooManyBitsCounter),
    .tooFewBitsCounter(tooFewBitsCounter),
    .outOfSeqCounter(outOfSeqCounter),
    .timestamp(timestamp),
    .timestampValid(timestampValid),
    .timestampHA(timestampHA),
    .timestampHAValid(timestampHAValid)
);

// Rely on the optimizer to clean out all unused event strobes
genvar e;
wire [254:1] evStrobe;
assign ppsMarker = evStrobe[EVCODE_SECONDS_MARKER];
for (e = 1 ; e <= 254 ; e = e + 1) begin : evstr
    reg evs;
    always @(posedge evrRxClk) begin
        evs <= (evCodeValid && (evCode == e));
    end
    assign evStrobe[e] = evs;
end

generate
if (ACTION_RAM_WIDTH > 0) begin
 //
 // Traditional lookup-table based actions
 //
 reg [ACTION_RAM_WIDTH-1:0] actionRAM [0:255], actionRAMQ, actionBus;
 reg ramQisValid = 0;
 always @(posedge sysClk) begin
    if (sysActionWriteEnable) begin
        actionRAM[sysActionAddress] <= sysActionData;
    end
 end
 always @(posedge evrRxClk) begin
    ramQisValid <= evCodeValid;
    actionRAMQ <= actionRAM[evCode];
    actionBus <= ramQisValid ? actionRAMQ : 0;
 end
 assign action = actionBus;
end
else begin
 //
 // Individual strobes per event
 //
 for (e = 1 ; e <= EVSTROBE_COUNT ; e = e + 1) begin : evact
    assign action[e] = evStrobe[e];
 end
end
endgenerate

endmodule
