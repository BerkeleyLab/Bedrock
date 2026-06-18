module evr_wrapper #(
    parameter DEBUG = "false",
    parameter GT_TYPE = "GTY",
    parameter integer FCNT_WIDTH = 24  // freq_count update rate: 125e6 / 2**24 = 1.9 kHz
) (
    // transceiver IOs
    input          gt_refclk_p,
    input          gt_refclk_n,
    input          gt_rxp,
    input          gt_rxn,
    output         gt_refclk_out,

    input          sys_clk,
    // should be leep input register
    input [7:0]    evcode,
    input [6:0]    evr_oc_delay,

    // evr_clk
    output         evr_clk,
    output         event1_evr,

    // dsp_clock
    input          dsp_clk,
    output         event1_dsp,
    output [63:0]  live_ts_dsp
);

    wire [31:0] gt_evr_status;
    wire [31:0] gt_rx_reset_cnt;
    wire [0:0]  evr_timestamp_valid;
    wire [15:0] evr_evcnt;
    wire [63:0] evr_live_ts_dsp;
    wire [31:0] gt_ref_freq;
    wire [31:0] gt_rx_freq;
    wire [0:0]  reset_all;

    // Instantiate the Timing Event Receiver (EVR)
    wire [15:0] evr_chars;
    wire [1:0] evr_charisk;

    wire rx_reset_done_sys;
    wire rx_aligned_sys;
    wire cplllocked_sys;

    evr_gt_wrapper #(
        .DEBUG(DEBUG),
        .GT_TYPE(GT_TYPE)
    ) evr_gt_wrapper (
        .gt_refclk_p        (gt_refclk_p),
        .gt_refclk_n        (gt_refclk_n),
        .gt_rxp_in          (gt_rxp),
        .gt_rxn_in          (gt_rxn),
        .gt_refclk_out      (gt_refclk_out),
        .sys_clk            (sys_clk),
        .soft_reset         (reset_all),
        .rx_reset_done_sys  (rx_reset_done_sys),
        .rx_aligned_sys     (rx_aligned_sys),
        .rx_fsm_reset_cnt   (gt_rx_reset_cnt),
        .cplllocked_sys     (cplllocked_sys),
        .rx_usrclk          (evr_clk),
        .rxdata             (evr_chars),
        .rxcharisk          (evr_charisk)
    );

    wire [31:0] evr_evcnt_sys;
    wire [0:0]  evr_ts_valid_sys;
    wire [0:0]  hb_valid_sys;
    wire [0:0]  pps_valid_sys;
    wire [0:0]  oc_valid_sys;
    wire [27:0] oc_evr_frequency;
    wire [0:0] evr_oc_trig_dsp;
    wire [63:0] evr_oc_ts_dsp;
    wire [0:0] evr_trig;
    timing_core timing_core (
        .evr_clk             (evr_clk),
        .evr_rxd             (evr_chars),
        .evr_rxk             (evr_charisk),
        .evcode_evr          (evcode),
        .event_evr           (),
	.oc_delay_evr        (evr_oc_delay),

        .sys_clk             (sys_clk),
        .event1_cnt_sys      (evr_evcnt_sys),
        .ts_valid_sys        (evr_ts_valid_sys),
        .live_ts_sys         (),
	.hb_valid_sys        (hb_valid_sys),
	.pps_valid_sys       (pps_valid_sys),
	.oc_valid_sys        (oc_valid_sys),
	.oc_evr_frequency    (oc_evr_frequency),

        .dsp_clk             (dsp_clk),
        .live_ts_dsp         (evr_live_ts_dsp),
        .pps_strobe_dsp      (),
        .hb_strobe_dsp       (),
        .event_dsp           (evr_trig),
        .oc_trig_dsp         (evr_oc_trig_dsp),
	.oc_ts_dsp           (evr_oc_ts_dsp)
    );

    freq_count #(
        .refcnt_width(FCNT_WIDTH),
        .freq_width(32)
    ) freq_count_refclk (
        .sysclk(sys_clk),
        .f_in(gt_refclk_out),
        .frequency(gt_ref_freq)
    );

    freq_count #(
        .refcnt_width(FCNT_WIDTH),
        .freq_width(32)
    ) freq_count_evrclk (
        .sysclk(sys_clk),
        .f_in(evr_clk),
        .frequency(gt_rx_freq)
    );

    initial begin
        $dumpfile("evr_wrapper.vcd");
        $dumpvars(20, evr_wrapper);
    end

endmodule

