`timescale 1ns / 1ns
// mostly cribbed from Osprey/Bedrock tinyEVR_tb.v

module evr_ts_cdc_tb;

parameter EVSTROBE_COUNT  = 12;
parameter ACTION_WIDTH    = 4;

parameter EVCODE_SHIFT_ZERO     = 8'h70;
parameter EVCODE_SHIFT_ONE      = 8'h71;
parameter EVCODE_SECONDS_MARKER = 8'h7D;

reg         evrClk = 1;
reg  [15:0] evrRxWord = 16'hx;
reg   [1:0] evrCharIsK = 2'hx;

always begin
    #4 evrClk <= !evrClk;
end

wire ppsMarker, timestampValid;
wire [63:0] timestamp;
wire [EVSTROBE_COUNT:1] evStrobe;

tinyEVR #(.EVSTROBE_COUNT(EVSTROBE_COUNT)) tinyEVR (
    .evrRxClk(evrClk),
    .evrRxWord(evrRxWord),
    .evrCharIsK(evrCharIsK),
    .ppsMarker(ppsMarker),
    .timestampValid(timestampValid),
    .timestamp(timestamp),
    .evStrobe(evStrobe)
);

wire [31:0] ts_secs, ts_tcks;
assign {ts_secs, ts_tcks} = timestamp;

reg usr_clk = 1;
wire [31:0] usr_secs, usr_tcks;

always begin
    #5 usr_clk <= !usr_clk;
end

evr_ts_cdc dut(
    .evr_clk(evrClk),
    .ts_secs(ts_secs), .ts_tcks(ts_tcks), .evr_pps(ppsMarker),
    .usr_clk(usr_clk),
    .usr_secs(usr_secs), .usr_tcks(usr_tcks)
);

reg fail=0;

// Check for unexpected tcks transitions
reg [31:0] usr_secs_r=0, usr_tcks_r=0;
wire jump = usr_secs != usr_secs_r;
reg jump_r=0;
always @(posedge usr_clk) begin
    usr_secs_r <= usr_secs;
    usr_tcks_r <= usr_tcks;
    jump_r <= jump;
end
integer dt;
always @(negedge usr_clk) begin
    dt = usr_tcks-usr_tcks_r;
    if (($time>100) & ~jump & ~jump_r & (dt < 1 || dt > 2)) begin
        $display("%d %d %d", $time, dt, usr_secs-usr_secs_r);
        fail = 1;
    end
    if ((jump | jump_r) & (usr_tcks!=0)) begin
        $display("%d %d %d", $time, dt, usr_secs-usr_secs_r);
        fail = 1;
    end
end

// Check for jitter
// Claim is "Time delay is one evr_clk plus one-to-two usr_clk cycles"
// For this test bench, that's 8 + (1 to 2)*10 = 18 to 28 ns.
integer edge_t;
integer del, min_del=10000, max_del=0;
always @(posedge ppsMarker) edge_t = $time;
always @(posedge jump) begin
    del = $time-edge_t;
    // $display("%d - %d = %d", $time, edge_t, $time-edge_t);
    if (del < min_del) min_del = del;
    if (del > max_del) max_del = del;
end

integer i;
initial
begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("evr_ts_cdc.vcd");
        $dumpvars(0, evr_ts_cdc_tb);
    end

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
    #1112 ;
    for (i = 0; i < 10; i += 1) begin
      sendEvent(EVCODE_SECONDS_MARKER);
      #1100 ;
    end
    $display("delay span %d to %d ns", min_del, max_del);
    if (min_del < 18) fail=1;
    if (max_del > 28) fail=1;
    if (fail) begin
      $display("FAIL");
      $stop(0);
    end else begin
      $display("PASS");
      $finish(0);
    end
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
