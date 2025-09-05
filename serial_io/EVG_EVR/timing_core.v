module timing_core #(
    parameter integer EVSTROBE_COUNT = 254
) (
    // evr_clk domain
    input             evr_clk,
    input [15:0]      evr_rxd,
    input [1:0]       evr_rxk,
    input [7:0]       evcode_evr,
    output            event_evr,

    // sys_clk domain
    input             sys_clk,
    output [31:0]     event1_cnt_sys,
    output            ts_valid_sys,
    output [63:0]     live_ts_sys,

    // dsp_clk domain
    input             dsp_clk,
    output [63:0]     live_ts_dsp,
    output            pps_marker_dsp,
    output            hb_marker_dsp,
    output            event_dsp
);

    // ---------------------
    // Timing Event Receiver (EVR)
    // ---------------------
    wire pps_marker_evr, ts_valid_evr;
    wire [63:0] live_ts_evr;
    wire [EVSTROBE_COUNT:1] evstrobe_evr;

    tinyEVR #(.EVSTROBE_COUNT(EVSTROBE_COUNT)) tinyEVR (
        .evrRxClk       (evr_clk),
        .evrRxWord      (evr_rxd),
        .evrCharIsK     (evr_rxk),
        .ppsMarker      (pps_marker_evr),
        .timestampValid (ts_valid_evr),
        .timestamp      (live_ts_evr),
        .evStrobe       (evstrobe_evr)
    );

    assign event_evr = evstrobe_evr[evcode_evr];

    reg_tech_cdc i_ts_valid_cdc (.I(ts_valid_evr), .C(sys_clk), .O(ts_valid_sys));

    // Start latching events only after timestamp has been recovered successfully to avoid registering
    // partially-decoded events
    reg [31:0] evcnt1_evr=0;
    // wire count_event = event_evr && ts_valid_evr;
    wire count_event = event_evr; // XXX bypass ts_valid_evr temporarily
    reg count_event_r=0;
    always @(posedge evr_clk) begin
        if (count_event) evcnt1_evr <= evcnt1_evr + 1;
        count_event_r <= count_event;
    end

    // CDC to sys_clk
    data_xdomain #(.size(32)) i_evcnt_sync (
        .clk_in   (evr_clk), .gate_in  (count_event_r),
        .data_in  (evcnt1_evr),
        .clk_out  (sys_clk), .gate_out (),
        .data_out (event1_cnt_sys)
    );

    flag_xdomain i_ev1 (.clk1(evr_clk), .flagin_clk1(event_evr),
                        .clk2(dsp_clk), .flagout_clk2(event_dsp));

    // timestamp (seconds and ticks) CDC to dsp_clk
    evr_ts_cdc i_evr_ts_cdc_dsp (
        .evr_clk(evr_clk),
        .ts_secs(live_ts_evr[63:32]), .ts_tcks(live_ts_evr[31:0]),
        .evr_pps(pps_marker_evr),
        .usr_clk(dsp_clk),
        .usr_secs(live_ts_dsp[63:32]), .usr_tcks(live_ts_dsp[31:0])
    );

    evr_ts_cdc i_evr_ts_cdc_sys (
        .evr_clk(evr_clk),
        .ts_secs(live_ts_evr[63:32]), .ts_tcks(live_ts_evr[31:0]),
        .evr_pps(pps_marker_evr),
        .usr_clk(sys_clk),
        .usr_secs(live_ts_sys[63:32]), .usr_tcks(live_ts_sys[31:0])
    );

    flag_xdomain i_pps (.clk1(evr_clk), .flagin_clk1(pps_marker_evr),
                        .clk2(dsp_clk), .flagout_clk2(pps_marker_dsp));

    localparam EVCODE_HEARTBEAT_MARKER = 8'h7A;
    flag_xdomain i_hb (.clk1(evr_clk), .flagin_clk1(evstrobe_evr[EVCODE_HEARTBEAT_MARKER]),
                        .clk2(dsp_clk), .flagout_clk2(hb_marker_dsp));

endmodule
