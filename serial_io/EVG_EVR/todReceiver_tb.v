// Scale time by a factor of 10000

`timescale 10us / 1ns

module todReceiver_tb #(
    parameter [7:0] EVCODE_SHIFT_ZERO     = 8'h70,
    parameter [7:0] EVCODE_SHIFT_ONE      = 8'h71,
    parameter [7:0] EVCODE_SECONDS_MARKER = 8'h7D,
    parameter NOMINAL_CLK_RATE = 10_000,
    parameter TIMESTAMP_WIDTH = 64,
    parameter TOD_SECONDS_WIDTH = TIMESTAMP_WIDTH / 2,
    parameter TOD_FRACTION_WIDTH = TIMESTAMP_WIDTH / 2,
    parameter TOD_TICKS_WIDTH = TIMESTAMP_WIDTH / 2,
    parameter integer TIMESTAMP_INVALID_ALLOWANCE = 5
);

reg clk;

integer cc;
integer errors = 0;

initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("todReceiver.vcd");
        $dumpvars(5,todReceiver_tb);
    end

    clk = 1;
    for (cc = 0; cc < 100000; cc = cc+1) begin
        clk = 1; #5;
        clk = 0; #5;
    end

	if (errors) begin
		$display("FAIL");
		$stop(0);
	end else begin
		$display("PASS");
		$finish(0);
	end
end

//////////////////////////////////
// PPS generation
//////////////////////////////////

integer tBase = 0;
reg pps = 0;

always @(posedge clk) begin
    if (($time - tBase) > 100000) begin
        if (($time - tBase) > 100010) begin
            tBase = tBase + 100000;
        end
        pps <= ~$time & 1;
    end
    else begin
        pps <= 0;
    end
end

localparam PPS_STROBE_DELAY_CHAIN_LENGTH = 3;

reg pps_d = 0;
reg ppsStrobe = 0;
reg ppsStrobe_d0 = 0, ppsStrobe_d1 = 0, ppsStrobe_d2 = 0;

always @(posedge clk) begin
    pps_d <= pps;
    ppsStrobe_d0 <= ppsStrobe;
    ppsStrobe_d1 <= ppsStrobe_d0;
    ppsStrobe_d2 <= ppsStrobe_d1;

    ppsStrobe <= 0;
    if (pps && !pps_d) begin
        ppsStrobe <= 1;
    end
end

//////////////////////////////////
// DUT
//////////////////////////////////

reg [7:0] evCode = 0;
reg evCodeValid = 0;
wire [TIMESTAMP_WIDTH-1:0] timestamp;
wire [TIMESTAMP_WIDTH-1:0] timestampHA;
wire timestampValid;
wire timestampHAValid;

todReceiver #(
    .NOMINAL_CLK_RATE(NOMINAL_CLK_RATE),
    .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH)
) DUT (
    .clk(clk),
    .rst(1'b0),

    .evCode(evCode),
    .evCodeValid(evCodeValid),

    .tooManyBitsCounter(),
    .tooFewBitsCounter(),
    .outOfSeqCounter(),
    .timestamp(timestamp),
    .timestampValid(timestampValid),
    .timestampHA(timestampHA),
    .timestampHAValid(timestampHAValid)
);

//////////////////////////////////
// Stimulus
//////////////////////////////////
localparam TOD_DELAY = 32;
localparam TOD_DELAY_WIDTH = $clog2(TOD_DELAY+1) + 1;
localparam TOD_BIT_COUNTER_WIDTH = $clog2(TOD_SECONDS_WIDTH+1) + 1;

reg todStart = 0;
reg [TOD_SECONDS_WIDTH-1:0] secondsNext = 32'h12345677;
reg [TOD_SECONDS_WIDTH-1:0] todShiftReg = 0;
reg [TOD_DELAY_WIDTH-1:0] todDelay = TOD_DELAY - 1;
reg [TOD_BIT_COUNTER_WIDTH-1:0] todBitCounter = TOD_SECONDS_WIDTH - 1;
wire todDelayDone = todDelay[TOD_DELAY_WIDTH-1];
wire todBitCounterDone = todBitCounter[TOD_BIT_COUNTER_WIDTH-1];

reg ppsRequest = 0;
reg todRequest = 0;

always @(posedge clk) begin
    if (ppsStrobe) begin
        secondsNext <= secondsNext + 1;
        ppsRequest <= 1;
        todDelay <= TOD_DELAY - 1;
        todBitCounter <= TOD_SECONDS_WIDTH - 1;
        todStart <= 1;
    end
    else if (todDelayDone) begin
        if (!todBitCounterDone && !todRequest) begin
            todRequest <= 1;
            todBitCounter <= todBitCounter - 1;

            if (todStart) begin
                todStart <= 0;
                todShiftReg <= secondsNext;
            end
            else begin
                todShiftReg <= {todShiftReg[TOD_SECONDS_WIDTH-2:0], 1'bx};
            end
        end
    end
    else begin
        todDelay <= todDelay + 1;
    end
end

always @(posedge clk) begin
    evCode <= 0;
    evCodeValid <= 0;

    if (ppsRequest) begin
        ppsRequest <= 0;

        evCode <= EVCODE_SECONDS_MARKER;
        evCodeValid <= 1;
    end
    else if (todRequest) begin
        todRequest <= 0;

        evCode <= todShiftReg[TOD_SECONDS_WIDTH-1] ? EVCODE_SHIFT_ONE :
            EVCODE_SHIFT_ZERO;
        evCodeValid <= 1;
    end
end

//////////////////////////////////
// Checks
//////////////////////////////////
integer timestampInvCounter = 0;
wire [TOD_SECONDS_WIDTH-1:0] tstampSecs = timestamp[TOD_FRACTION_WIDTH+:TOD_SECONDS_WIDTH];
wire [TOD_FRACTION_WIDTH-1:0] tstampFraction = timestamp[0+:TOD_FRACTION_WIDTH];

always @(posedge clk) begin
    // It takes 2 clock cycles after ppsStrobe for the
    // todReceiver to perceive that + 1 clock cycle for
    // the seconds latch
    if (ppsStrobe_d2) begin
        if (!timestampHAValid) begin
            timestampInvCounter = timestampInvCounter + 1;
            if (timestampInvCounter > TIMESTAMP_INVALID_ALLOWANCE) begin
                errors = errors + 1;
                $display("ERROR: Timestamp was not valid after %d PPS",
                    TIMESTAMP_INVALID_ALLOWANCE);
            end
        end
        else begin
            if (secondsNext != tstampSecs + 1) begin
                errors = errors + 1;
                $display("ERROR: Unexpected seconds: %d, expected: %d",
                    tstampSecs, secondsNext);
            end
        end
    end
end

endmodule
