//  Time of day receiver module
//
//  It receives time stamp control events to set the
//  time of day from the GPS locked NTP server (usually
//  an upstream event generator).
//
//  This design was heavily based on W. Eric Norum module
//  to count seconds' fraction by measuring the clock rate

module todReceiver #(
    parameter       NOMINAL_CLK_RATE      = 125_000_000,
    parameter       TIMESTAMP_WIDTH       = 64,
    parameter [7:0] EVCODE_SHIFT_ZERO     = 8'h70,
    parameter [7:0] EVCODE_SHIFT_ONE      = 8'h71,
    parameter [7:0] EVCODE_SECONDS_MARKER = 8'h7D,
    parameter       STATUS_COUNTER_WIDTH  = 10
) (
    input                                    clk,
    input                                    rst,

    input wire                         [7:0] evCode,
    input wire                               evCodeValid,

    output reg    [STATUS_COUNTER_WIDTH-1:0] tooManyBitsCounter = 0,
    output reg    [STATUS_COUNTER_WIDTH-1:0] tooFewBitsCounter = 0,
    output reg    [STATUS_COUNTER_WIDTH-1:0] outOfSeqCounter = 0,
    output wire   [TIMESTAMP_WIDTH-1:0]      timestamp,
    output wire                              timestampValid,
    output wire   [TIMESTAMP_WIDTH-1:0]      timestampHA,
    output wire                              timestampHAValid
);

localparam SECONDS_WIDTH = TIMESTAMP_WIDTH/2;
localparam FRACTION_WIDTH = TIMESTAMP_WIDTH/2;
reg [SECONDS_WIDTH-1:0] seconds = 0, expectSeconds = 0;

localparam TICKS_WIDTH = TIMESTAMP_WIDTH/2;
reg [TICKS_WIDTH-1:0] ticks = 0;

// High-accuracy timestamp
assign timestampHA = {seconds, fraction};
// Old-style timestamp, counting ticks. Kept for compatibility
assign timestamp = {seconds, ticks};

reg         [SECONDS_WIDTH-1:0] shiftReg;
reg [$clog2(SECONDS_WIDTH)-1:0] bitsLeft = SECONDS_WIDTH - 1;
reg enoughBits = 0, tooManyBits = 0;

// Count clocks per second
localparam real NOMINAL_CLK_RATE_REAL = NOMINAL_CLK_RATE;
localparam real NOMINAL_CLK_RATE_PERCENT = NOMINAL_CLK_RATE_REAL / 100;
localparam PPS_INITIAL_INTERVAL = $rtoi(NOMINAL_CLK_RATE_PERCENT * 99);
localparam PPS_WINDOW_INTERVAL = NOMINAL_CLK_RATE / 50;
localparam CLK_COUNTER_WIDTH = $clog2(PPS_INITIAL_INTERVAL+PPS_WINDOW_INTERVAL+1);

// Low pass filter clocks per second
localparam FRACTION_WIDEN = 12;
localparam FILTER_L2_ALPHA = 4;
localparam FILTER_ACCUMULATOR_WIDTH = CLK_COUNTER_WIDTH + FILTER_L2_ALPHA;
reg [FILTER_ACCUMULATOR_WIDTH-1:0] filterAccumulator =
                                                    NOMINAL_CLK_RATE << FILTER_L2_ALPHA;
wire [CLK_COUNTER_WIDTH-1:0] filteredClocksPerSecond =
             filterAccumulator[FILTER_ACCUMULATOR_WIDTH-1-:CLK_COUNTER_WIDTH];

// Validate PPS
localparam PPS_INITIAL_WIDTH = $clog2(PPS_INITIAL_INTERVAL+1)+1;
localparam PPS_WINDOW_WIDTH = $clog2(PPS_WINDOW_INTERVAL+1)+1;

// Accumlate fractional seconds
localparam FRACTION_ACCUMULATOR_WIDTH = 32 + FRACTION_WIDEN;
localparam FRACTION_INCREMENT_WIDTH = $clog2((1<<30)/(PPS_INITIAL_INTERVAL/4)) +
                                                                 FRACTION_WIDEN;

wire ppsStrobe = evCodeValid && (evCode == EVCODE_SECONDS_MARKER);

///////////////////////////////////////////////////////////////////////////////
// Measure clock rate
///////////////////////////////////////////////////////////////////////////////

reg [2:0] ppsValidCounter = 0;
wire ppsValid = ppsValidCounter[2];

reg [CLK_COUNTER_WIDTH-1:0] clockCounter = 0;
reg [PPS_INITIAL_WIDTH-1:0] ppsInitial = 0;
reg [PPS_WINDOW_WIDTH-1:0] ppsWindow = 0;

wire ppsInitialDone = ppsInitial[PPS_INITIAL_WIDTH-1];
wire ppsWindowDone = ppsWindow[PPS_WINDOW_WIDTH-1];

always @(posedge clk) begin
    if (ppsStrobe) begin
        clockCounter <= 1;
        ppsInitial <= PPS_INITIAL_INTERVAL - 1;
        ppsWindow <= PPS_WINDOW_INTERVAL - 1;
        if (ppsInitialDone && !ppsWindowDone) begin
            if (!ppsValid) begin
                ppsValidCounter <= ppsValidCounter + 1;
            end
        end
        else begin
            ppsValidCounter <= 0;
        end
    end
    else begin
        clockCounter <= clockCounter + 1;
        if (ppsInitialDone) begin
            if (ppsWindowDone) begin
                ppsValidCounter <= 0;
            end
            else begin
                ppsWindow <= ppsWindow - 1;
            end
        end
        else begin
            ppsInitial <= ppsInitial - 1;
        end
    end
end

///////////////////////////////////////////////////////////////////////////////
// Compute fractional seconds increment
///////////////////////////////////////////////////////////////////////////////

// Compute fractional second increment from filtered clocks per second
localparam DIVIDER_BITCOUNT_WIDTH = $clog2(FRACTION_INCREMENT_WIDTH)+1;

reg [DIVIDER_BITCOUNT_WIDTH-1:0] dividerBitsLeft;
wire dividerDone = dividerBitsLeft[DIVIDER_BITCOUNT_WIDTH-1];

reg [CLK_COUNTER_WIDTH:0] dividend;
reg [FRACTION_INCREMENT_WIDTH-1:0] quotient;
reg dividerStart = 0;
reg [FRACTION_INCREMENT_WIDTH-1:0] fractionIncrement =
                                   {1'b1, {32+FRACTION_WIDEN{1'b0}}} / NOMINAL_CLK_RATE;

always @(posedge clk) begin
    // First low-pass filter the clock rate measurement
    if (ppsStrobe && ppsInitialDone && !ppsWindowDone) begin
        filterAccumulator <= filterAccumulator -
                             (filterAccumulator >> FILTER_L2_ALPHA) +
                             clockCounter;
        dividerStart <= 1;
    end
    else begin
        dividerStart <= 0;
    end

    // Then compute the fraction increment:
    // fractionIncrement = (2^(32 + FILTER_L2_ALPHA)) / filteredClocksPerSecond
    if (dividerStart) begin
        dividerBitsLeft <= FRACTION_INCREMENT_WIDTH;
        dividend <= {1'b1, {CLK_COUNTER_WIDTH-1{1'b0}}};
    end
    else if (!dividerDone) begin
        dividerBitsLeft <= dividerBitsLeft - 1;
        if (dividend >= filteredClocksPerSecond) begin
            dividend <= (dividend - filteredClocksPerSecond) << 1;
            quotient <= (quotient << 1) | 1;
        end
        else begin
            dividend <= dividend << 1;
            quotient <= (quotient << 1);
        end
    end
    else begin
        fractionIncrement <= quotient;
    end
end

///////////////////////////////////////////////////////////////////////////////
// Update fraction seconds
///////////////////////////////////////////////////////////////////////////////

reg [FRACTION_ACCUMULATOR_WIDTH-1:0] fractionAccumulator;
wire [FRACTION_ACCUMULATOR_WIDTH:0] nextFractionAccumulator =
                                        fractionAccumulator + fractionIncrement;
wire fractionOverflow = nextFractionAccumulator[FRACTION_ACCUMULATOR_WIDTH];
wire [FRACTION_WIDTH-1:0] fraction = fractionAccumulator[FRACTION_ACCUMULATOR_WIDTH-1-:FRACTION_WIDTH];

always @(posedge clk) begin
    if (rst) begin
        fractionAccumulator <= 0;
    end
    else begin
        // Update fractional seconds
        if (ppsStrobe) begin
            fractionAccumulator <= 0;
        end
        else if (fractionOverflow) begin
            fractionAccumulator <= ~0;
        end
        else begin
            fractionAccumulator <= fractionAccumulator + fractionIncrement;
        end
    end
end

///////////////////////////////////////////////////////////////////////////////
// Status counters
///////////////////////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        tooFewBitsCounter <= 0;
        tooFewBitsCounter <= 0;
    end
    else begin
        if (ppsStrobe) begin
            if (!enoughBits)
                tooFewBitsCounter <= tooFewBitsCounter + 1;

            if (tooManyBits)
                tooManyBitsCounter <= tooManyBitsCounter + 1;
        end
    end
end

///////////////////////////////////////////////////////////////////////////////
// Seconds receiver
///////////////////////////////////////////////////////////////////////////////

reg secondsValid = 0;

assign timestampHAValid = secondsValid && ppsValid;
assign timestampValid = secondsValid;

always @(posedge clk) begin
    if (rst) begin
        seconds <= 0;
        ticks <= 0;
        secondsValid <= 0;
        enoughBits <= 0;
        tooManyBits <= 0;
    end
    else begin
        if (ppsStrobe) begin
            if (enoughBits && !tooManyBits) begin
                expectSeconds <= shiftReg + 1;
                seconds <= shiftReg;
                secondsValid <= 1;

                if (shiftReg != expectSeconds) begin
                    outOfSeqCounter <= outOfSeqCounter + 1;
                end
            end
            else if (secondsValid) begin
                seconds <= seconds + 1;
            end

            ticks <= 0;
            bitsLeft <= SECONDS_WIDTH - 1;
            enoughBits <= 0;
            tooManyBits <= 0;
        end
        else begin
            if (fractionOverflow) begin
                secondsValid <= 0;
            end

            if (ticks[TICKS_WIDTH-1] == 0) begin
                ticks <= ticks + 1;
            end
            else begin
                secondsValid <= 0;
            end
        end

        if(evCodeValid &&
            (evCode == EVCODE_SHIFT_ZERO) || (evCode == EVCODE_SHIFT_ONE)) begin
            // Shift in another bit of upcoming seconds
            bitsLeft <= bitsLeft - 1;
            if (enoughBits)
                tooManyBits <= 1;

            if (bitsLeft == 0)
                enoughBits <= 1;

            shiftReg <= {shiftReg[SECONDS_WIDTH-2:0], evCode[0]};
        end
    end
end

endmodule
