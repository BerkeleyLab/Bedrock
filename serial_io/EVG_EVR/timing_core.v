module timing_core #(
    parameter integer EVSTROBE_COUNT = 254,
    // applicable only to synchrotron facilties
    parameter HARMONIC_N = 304, // Must be divisible by 4
    parameter SYSCLK_FREQUENCY = 125000000
) (
    // evr_clk domain
    input             evr_clk,
    input [15:0]      evr_rxd,
    input [1:0]       evr_rxk,
    input [7:0]       evcode_evr,
    output            event_evr,
    input [6:0]       oc_delay_evr,

    // sys_clk domain
    input             sys_clk,
    output [31:0]     event1_cnt_sys,
    output            ts_valid_sys,
    output [63:0]     live_ts_sys,
    // will be all zero for LINAC
    output            hb_valid_sys,
    output            pps_valid_sys,
    output            oc_valid_sys,
    output [27:0]     oc_evr_frequency,

    // dsp_clk domain
    input             dsp_clk,
    output [63:0]     live_ts_dsp,
    output            pps_strobe_dsp,
    output            hb_strobe_dsp,
    output            event_dsp,
    // will be all zero for LINAC
    output            oc_trig_dsp,
    output [63:0]     oc_ts_dsp
);

    // ---------------------
    // Timing Event Receiver (EVR)
    // ---------------------
    wire pps_strobe_evr, ts_valid_evr;
    wire [63:0] live_ts_evr;
    wire [EVSTROBE_COUNT:1] evstrobe_evr;

    tinyEVR #(.EVSTROBE_COUNT(EVSTROBE_COUNT)) tinyEVR (
        .evrRxClk       (evr_clk),
        .evrRxWord      (evr_rxd),
        .evrCharIsK     (evr_rxk),
        .ppsMarker      (pps_strobe_evr),
        .timestampValid (ts_valid_evr),
        .timestamp      (live_ts_evr),
        .evStrobe       (evstrobe_evr)
    );

    assign event_evr = evstrobe_evr[evcode_evr];

    reg_tech_cdc i_ts_valid_cdc (.I(ts_valid_evr), .C(sys_clk), .O(ts_valid_sys));

    // Start latching events only after timestamp has been recovered successfully
    // to avoid registering partially-decoded events
    reg [31:0] evcnt1_evr=0;
    wire count_event = event_evr && ts_valid_evr;
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
        .evr_pps(pps_strobe_evr),
        .usr_clk(dsp_clk),
        .usr_secs(live_ts_dsp[63:32]), .usr_tcks(live_ts_dsp[31:0])
    );

    // timestamp (seconds and ticks) CDC to sys_clk
    evr_ts_cdc i_evr_ts_cdc_sys (
        .evr_clk(evr_clk),
        .ts_secs(live_ts_evr[63:32]), .ts_tcks(live_ts_evr[31:0]),
        .evr_pps(pps_strobe_evr),
        .usr_clk(sys_clk),
        .usr_secs(live_ts_sys[63:32]), .usr_tcks(live_ts_sys[31:0])
    );

    flag_xdomain i_pps (.clk1(evr_clk), .flagin_clk1(pps_strobe_evr),
                        .clk2(dsp_clk), .flagout_clk2(pps_strobe_dsp));

    localparam EVCODE_HEARTBEAT_MARKER = 8'h7A;
    flag_xdomain i_hb (.clk1(evr_clk), .flagin_clk1(evstrobe_evr[EVCODE_HEARTBEAT_MARKER]),
                        .clk2(dsp_clk), .flagout_clk2(hb_strobe_dsp));

    // Following will only apply to synchroton facilities
    // Orbit clock recovery
    // Validates PPS and Heartbeat events by testing that they're close to 1 Hz in the
    // destination clock domain
    wire oc_valid_evr, oc_evr;
    evrSROC #(
	    .SYSCLK_FREQUENCY(SYSCLK_FREQUENCY),
	    .SROC_DIVIDER(HARMONIC_N/4))
    i_evrAROC (
	    .sysClk                  (sys_clk),
	    .evrClk                  (evr_clk),
	    .evrHeartbeatMarker      (evstrobe_evr[EVCODE_HEARTBEAT_MARKER]),
	    .evrPulsePerSecondMarker (pps_strobe_evr),

	    .heartBeatValid          (hb_valid_sys),  // in sys_clk
	    .pulsePerSecondValid     (pps_valid_sys),  // in sys_clk
	    .evrSROCsynced           (oc_valid_evr),  // in evr_clk
	    .evrSROC                 (oc_evr)  // in evr_clk
    );

    freq_count #(.refcnt_width (16)) fcnt_oc_clk (
	    .sysclk     (sys_clk),
	    .f_in       (oc_evr),
	    .frequency  (oc_evr_frequency)
    );

    reg_tech_cdc i_ocv (.I(oc_valid_evr), .C(sys_clk), .O(oc_valid_sys));
    // Live timestamp and orbit clock trigger
    // Orbit clock is simply synchronized (after an optional delay) to dsp_clk domain
    // alongside the exact timestamp derived from the timing stream.
    // The synchronization delay is variable, but predictable, and
    // depends on where the orbit clock rising-edge falls w.r.t dsp_clk
    reg oc_evr_r=0;
    always @(posedge evr_clk) oc_evr_r <= oc_evr;
    wire oc_trig_evr_l = oc_evr & ~oc_evr_r;

    // Optionally delay oc_trig and pick right timestamp in evr_clk domain
    reg [6:0] oc_cnt_evr=0;
    reg oc_trig_delay_inprog=0;
    always @(posedge evr_clk) begin
        if (oc_trig_evr_l) begin
            oc_cnt_evr <= 1;
            oc_trig_delay_inprog <= 1;
        end else if (oc_trig_delay_inprog) begin
            oc_cnt_evr <= oc_cnt_evr + 1;
            if (oc_cnt_evr == oc_delay_evr) oc_trig_delay_inprog <= 0;
        end
    end
    wire oc_trig_evr = oc_trig_delay_inprog && (oc_cnt_evr == oc_delay_evr);

    data_xdomain #(.size(64)) i_oc_sync (
	    .clk_in   (evr_clk), .gate_in  (oc_trig_evr),
	    .data_in  (live_ts_evr),
	    .clk_out  (dsp_clk), .gate_out (oc_trig_dsp),
	    .data_out (oc_ts_dsp)
    );

endmodule
