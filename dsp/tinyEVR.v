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

// Very small subset of MRF event receiver
// Provides time stamps, event strobes and some status markers.

module tinyEVR #(
    parameter EVSTROBE_COUNT  = 126,
    parameter TIMESTAMP_WIDTH = 64,
    parameter DEBUG           = "false"
    ) (
    input  wire                                            evrRxClk,

    (*mark_debug=DEBUG*) input  wire                [15:0] evrRxWord,
    (*mark_debug=DEBUG*) input  wire                 [1:0] evrCharIsK,

    (*mark_debug=DEBUG*) output wire                       ppsMarker,
    (*mark_debug=DEBUG*) output reg                        timestampValid = 0,
    (*mark_debug=DEBUG*) output wire [TIMESTAMP_WIDTH-1:0] timestamp,
    (*mark_debug=DEBUG*) output reg     [EVSTROBE_COUNT:1] evStrobe = 0,
                         output wire                 [7:0] distributedDataBus);

localparam SECONDS_WIDTH = TIMESTAMP_WIDTH/2;
localparam TICKS_WIDTH   = TIMESTAMP_WIDTH/2;
reg [SECONDS_WIDTH-1:0] tsSeconds = 0;
reg   [TICKS_WIDTH-1:0] tsTicks = 0;
assign timestamp = {tsSeconds, tsTicks};

localparam EVCODE_SHIFT_ZERO     = 8'h70;
localparam EVCODE_SHIFT_ONE      = 8'h71;
localparam EVCODE_SECONDS_MARKER = 8'h7D;

(*mark_debug=DEBUG*) reg           [SECONDS_WIDTH-1:0] shiftReg;
(*mark_debug=DEBUG*) reg [$clog2(SECONDS_WIDTH)-1:0] bitsLeft = SECONDS_WIDTH - 1;
(*mark_debug=DEBUG*) reg enoughBits = 0, tooManyBits = 0;

wire [7:0] evCode = evrRxWord[7:0];
assign distributedDataBus = evrRxWord[15:8];
wire evCodeValid = !evrCharIsK[0];

always @(posedge evrRxClk) begin
    // Update time stamp seconds and clear time stamp ticks
    // on arrival of 'pulse per second' marker event code.
    if (evCodeValid && (evCode == EVCODE_SECONDS_MARKER)) begin
        if (enoughBits && !tooManyBits) begin
            tsSeconds <= shiftReg;
            timestampValid <= 1;
        end
        else if (timestampValid) begin
            tsSeconds <= tsSeconds + 1;
        end
        tsTicks <= 0;
        bitsLeft <= SECONDS_WIDTH - 1;
        enoughBits <= 0;
        tooManyBits <= 0;
    end
    else if (tsTicks[TICKS_WIDTH-1] == 0) begin
        tsTicks <= tsTicks + 1;
    end
    else begin
        timestampValid <= 0;
    end

    // Shift in another bit of upcoming seconds
    if (evCodeValid
     && ((evCode == EVCODE_SHIFT_ZERO) || (evCode == EVCODE_SHIFT_ONE))) begin
        bitsLeft <= bitsLeft - 1;
        if (enoughBits) tooManyBits <= 1;
        if (bitsLeft == 0) enoughBits <= 1;
        shiftReg <= {shiftReg[SECONDS_WIDTH-2:0], evCode[0]};
    end
end

// Generate event strobes
// Rely on synthesis optimizer to remove unused outputs
assign ppsMarker = evStrobe[EVCODE_SECONDS_MARKER];
genvar e;
generate
for (e = 1 ; e <= EVSTROBE_COUNT ; e = e + 1) begin : evstr
    always @(posedge evrRxClk) begin
        evStrobe[e] <= (evCodeValid && (evCode == e));
    end
end
endgenerate

endmodule
