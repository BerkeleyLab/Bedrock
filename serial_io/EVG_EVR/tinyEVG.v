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

// Very small subset of MRF event generator
// Provides heartbeats, time stamps, arbitrary events

module tinyEVG #(
    parameter EVG_CLOCK_RATE= 125000000,
    parameter SECONDS_WIDTH = 32,
    parameter DEBUG         = "false"
    ) (
    // Connection to transmitter
    input  wire                     evgTxClk,
    output wire              [15:0] evgTxWord,
    output wire               [1:0] evgTxIsK,

    // Interval for 'heartbeat' event
    input  wire              [31:0] heartbeatInterval,

    // Arbitrary event requests
    input  wire               [7:0] distributedBus,
    input  wire               [7:0] eventCode,
    input  wire                     eventStrobe,

    // Following inputs can be clock domains other than evgTxClk
    // On the debounced rising edge of ppsMarker_a the ppsToggle
    // changes state.  The higher level logic takes this as an indication
    // that a new value for seconds_a is expected.
    input  wire                     ppsMarker_a,
    output reg                      ppsToggle = 0,
    input  wire [SECONDS_WIDTH-1:0] seconds_a);

localparam EVCODE_SHIFT_ZERO     = 8'h70;
localparam EVCODE_SHIFT_ONE      = 8'h71;
localparam EVCODE_HEARTBEAT      = 8'h7A;
localparam EVCODE_SECONDS_MARKER = 8'h7D;
localparam EVCODE_K28_5          = 8'hBC;

(* mark_debug = DEBUG *) reg [SECONDS_WIDTH-1:0] secondsShiftReg;
(* mark_debug = DEBUG *) reg [$clog2(SECONDS_WIDTH+1)-1:0] secondsBitcount = 0;
(* mark_debug = DEBUG *) reg [1:0] secondsGap = 0;
(* mark_debug = DEBUG *) reg [1:0] commaGap = 0;

localparam PPS_DEBOUNCE_TIMER_RELOAD = ((EVG_CLOCK_RATE/100000))-1;
reg [$clog2(PPS_DEBOUNCE_TIMER_RELOAD+1)-1:0]ppsDebounceTimer = PPS_DEBOUNCE_TIMER_RELOAD;

// Move ppsMarker_a to our clock domain
wire ppsMarker;
reg_async_cdc ppsMarker_cdc(.I(ppsMarker_a), .C(evgTxClk), .O(ppsMarker));

reg ppsMarker_delayed = 0, ppsMatch = 0;
reg [31:0] heartbeatCounter = EVG_CLOCK_RATE - 1;
(* mark_debug = DEBUG *) reg heartbeatRequest = 0;

// Event codes and commas appear only in least significant byte
reg [7:0] txCode;
reg       txCodeIsK = 0;
assign evgTxWord = { distributedBus, txCode };
assign evgTxIsK = { 1'b0, txCodeIsK };

always @(posedge evgTxClk) begin
    // Timer housekeeping
    if (secondsGap) secondsGap <= secondsGap - 1;
    if (commaGap) commaGap <= commaGap - 1;

    // Heartbeat event generation
    if (heartbeatInterval > 20) begin
        if (heartbeatCounter == 0) begin
            heartbeatCounter <= heartbeatInterval -1;
            heartbeatRequest <= 1;
        end
        else begin
            heartbeatCounter <= heartbeatCounter - 1;
            heartbeatRequest <= 0;
        end
    end
    else begin
        heartbeatCounter <= 0;
        heartbeatRequest <= 0;
    end

    // Require PPS marker to be low for 10 us before detecting a rising edge
    if (ppsMarker) begin
        if (!ppsMarker_delayed) begin
            ppsToggle <= !ppsToggle;
            secondsShiftReg <= seconds_a;
        end
        ppsMarker_delayed <= 1;
        ppsDebounceTimer <= PPS_DEBOUNCE_TIMER_RELOAD;
    end
    else if (ppsDebounceTimer) begin
        ppsDebounceTimer <= ppsDebounceTimer - 1;
    end
    else begin
        ppsMarker_delayed <= 0;
    end

    // Send events in priority order
    // External request
    if (eventStrobe) begin
        txCode <= eventCode;
        txCodeIsK <= 0;
    end
    // Then heartbeats -- may be inhibited by FIFO event, but never delayed.
    else if (heartbeatRequest) begin
        txCode <= EVCODE_HEARTBEAT;
        txCodeIsK <= 0;
    end
    // Then PPS markers (which could be delayed by an arbitrary amount.
    // Best practice is to ensure gap between external requests
    else if (ppsMatch != ppsToggle) begin
        ppsMatch <= !ppsMatch;
        txCode <= EVCODE_SECONDS_MARKER;;
        txCodeIsK <= 0;
        secondsBitcount <= SECONDS_WIDTH;
        secondsGap <= ~0;
    end
    // POSIX seconds shift register has Lowest priority
    else if ((secondsBitcount != 0) && (secondsGap == 0)) begin
        secondsGap <= ~0;
        secondsBitcount <= secondsBitcount - 1;
        secondsShiftReg <= { secondsShiftReg[0+:SECONDS_WIDTH-1], 1'b0 };
        txCode <= secondsShiftReg[SECONDS_WIDTH-1] ? EVCODE_SHIFT_ONE :
                                                        EVCODE_SHIFT_ZERO;
        txCodeIsK <= 0;
    end
    else if (commaGap == 0) begin
        commaGap <= ~0;
        txCode <= EVCODE_K28_5;
        txCodeIsK <= 1;
    end
    else begin
        txCode <= 0;
        txCodeIsK <= 0;
    end
end

endmodule
