// Monitor EVR and generate Storage Ring Orbit Clock
// Nets with names beginning with evr are in the EVR clock domain.

module evrSROC #(
    parameter SYSCLK_FREQUENCY = -1,
    parameter SROC_DIVIDER     = -1,
    parameter DEBUG            = "false"
    ) (
    input  sysClk,
    input  evrClk,
    (*mark_debug=DEBUG*) input evrHeartbeatMarker,
    (*mark_debug=DEBUG*) input evrPulsePerSecondMarker,

    output wire heartBeatValid,
    output wire pulsePerSecondValid,
    (*mark_debug=DEBUG*) output reg  evrSROCsynced = 0,
    (*mark_debug=DEBUG*) output reg  evrSROC = 0);

localparam RELOAD_LO = ((SROC_DIVIDER + 1) / 2) - 1;
localparam RELOAD_HI = (SROC_DIVIDER / 2) - 1;
(*mark_debug=DEBUG*) reg [$clog2(RELOAD_LO+1)-1:0] srocCounter;
reg evrHeartbeatMarker_d;
always @(posedge evrClk) begin
    evrHeartbeatMarker_d <= evrHeartbeatMarker;
    if (evrHeartbeatMarker && !evrHeartbeatMarker_d) begin
        evrSROC <= 0;
        srocCounter <= RELOAD_LO;
        if (evrSROC && (srocCounter == 0)) begin
            evrSROCsynced <= 1;
        end
        else begin
            evrSROCsynced <= 0;
        end
    end
    else if (srocCounter == 0) begin
        evrSROC <= !evrSROC;
        srocCounter <= evrSROC ? RELOAD_LO : RELOAD_HI;
    end else begin
        srocCounter <= srocCounter - 1;
    end
end

eventMarkerWatchdog #(.SYSCLK_FREQUENCY(SYSCLK_FREQUENCY),
                      .DEBUG(DEBUG))
  hbWatchdog (.sysClk(sysClk),
              .evrMarker(evrHeartbeatMarker),
              .isValid(heartBeatValid));

eventMarkerWatchdog #(.SYSCLK_FREQUENCY(SYSCLK_FREQUENCY),
                      .DEBUG(DEBUG))
  ppsWatchdog (.sysClk(sysClk),
               .evrMarker(evrPulsePerSecondMarker),
               .isValid(pulsePerSecondValid));
endmodule

module eventMarkerWatchdog #(
    parameter SYSCLK_FREQUENCY = 100000000,
    parameter DEBUG            = "false"
    ) (
    input      sysClk,
    input      evrMarker,
    output reg isValid = 0);

localparam UPPER_LIMIT = (SYSCLK_FREQUENCY * 11) / 10;
localparam LOWER_LIMIT = (SYSCLK_FREQUENCY *  9) / 10;
(*mark_debug=DEBUG*) reg [$clog2(LOWER_LIMIT+1)-1:0] watchdog;
(* ASYNC_REG="TRUE" *) reg marker_m, marker;
(* mark_debug=DEBUG *) reg marker_d;

always @(posedge sysClk) begin
    marker_m <= evrMarker;
    marker   <= marker_m;
    marker_d <= marker;
    if (marker && !marker_d) begin
        watchdog <= 0;
        if ((watchdog > LOWER_LIMIT)
         && (watchdog < UPPER_LIMIT)) begin
            isValid <= 1;
        end
        else begin
            isValid <= 0;
        end
    end
    else if (watchdog < UPPER_LIMIT) begin
        watchdog <= watchdog + 1;
    end
    else begin
        isValid <= 0;
    end
end
endmodule
