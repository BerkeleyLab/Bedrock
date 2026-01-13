// Wrapper around wizard-generated transceiver

module evr_gt_wrapper #(
    parameter DEBUG = "false",
    parameter GT_TYPE = "GTY",
    parameter integer CHECK_TIMEOUT = 125000
) (
    // GT ports
    input       gt_refclk_p,
    input       gt_refclk_n,
    input       gt_rxp_in,
    input       gt_rxn_in,
    output      gt_refclk_out,

    // sys_clk domain
    input       sys_clk,
    (*mark_debug=DEBUG*) input          soft_reset,
    (*mark_debug=DEBUG*) output         rx_reset_done_sys,
    (*mark_debug=DEBUG*) output         rx_aligned_sys,
    (*mark_debug=DEBUG*) output         cplllocked_sys,
    (*mark_debug=DEBUG*) output [31:0]  rx_fsm_reset_cnt,

    // rx_usrclk domain
    output             rx_usrclk,
    output reg [15:0]  rxdata = 0,
    output reg [1:0]   rxcharisk = 0
);
    // rx_usrclk domain
    wire rx_aligned;
    wire [15:0] rxdata_out;
    wire [1:0] rxdisperr_out, rxnotintable_out, rxcharisk_out;

    wire [1:0] comma_seen;
    assign comma_seen[0] = rxcharisk_out[0] & (rxdata_out[0+:8] == 8'hBC);
    assign comma_seen[1] = rxcharisk_out[1] & (rxdata_out[8+:8] == 8'hBC);

    // Allow commas (SOF, EOP - special ones) in the MSB,
    // since MRF can support the "data protocol" on the dbus
    // see page 12 of the [EVG MRF document](http://www.mrf.fi/dmdocuments/EVG-TREF-004.pdf)
    wire error_seen = (rxnotintable_out != 0) || (rxdisperr_out != 0);

    (*mark_debug=DEBUG*) wire error_seen_sys, comma_seen_sys;
    reg_tech_cdc error_seen_x (.I(error_seen), .C(sys_clk), .O(error_seen_sys));
    reg_tech_cdc comma_seen_x (.I(comma_seen[0]), .C(sys_clk), .O(comma_seen_sys));

    (*mark_debug=DEBUG*) wire soft_reset_all, rx_fsm_reset_out;
    // sys_clk domain
    evr_reset_fsm #(
        .DEBUG          ("true"),
        .COMMAS_NEEDED  (60),
        .CHECK_TIMEOUT  (CHECK_TIMEOUT)
    ) evr_reset_fsm_i (
        .clk            (sys_clk),
        .rst            (1'b0),
        .error_seen     (error_seen_sys),
        .comma_seen     (comma_seen_sys),
        .reset_done     (rx_reset_done_sys),
        .reset_out      (rx_fsm_reset_out),
        .ready_out      (rx_aligned_sys),
        .reset_out_cnt  (rx_fsm_reset_cnt)
    );
    // combine fsm reset output and soft_reset from control bus
    assign soft_reset_all = rx_fsm_reset_out | soft_reset;

    reg_tech_cdc rx_aligned_x (.I(rx_aligned_sys), .C(rx_usrclk), .O(rx_aligned));

    // Pass event codes out, only when we are aligned
    always @(posedge rx_usrclk) begin
        rxdata <= rx_aligned ? rxdata_out : 16'd0;
        rxcharisk <= rxcharisk_out;
    end

    // ---------------------
    // Instantiate EVR GT wrapper
    // ---------------------
    gt_wrapper #(
        .GT_TYPE(GT_TYPE)
    ) gt_wrapper_i (
        // GT ports
        .gt_refclk_p        (gt_refclk_p),
        .gt_refclk_n        (gt_refclk_n),
        .gt_rxp_in          (gt_rxp_in),
        .gt_rxn_in          (gt_rxn_in),
        .gt_refclk_out      (gt_refclk_out),

        // rx_usrclk domain
        .rx_usrclk          (rx_usrclk),
        .rxdata_out         (rxdata_out),
        .rxdisperr_out      (rxdisperr_out),
        .rxnotintable_out   (rxnotintable_out),
        .rxcharisk_out      (rxcharisk_out),

        // sys_clk domain
        .sys_clk            (sys_clk),
        .soft_reset         (soft_reset_all),
        .cplllocked_sys     (cplllocked_sys),
        .rx_reset_done_sys  (rx_reset_done_sys)
    );
endmodule


module evr_reset_fsm #(
    parameter DEBUG = "false",
    parameter integer COMMAS_NEEDED = 60,
    parameter integer CHECK_TIMEOUT = 125000  // ~125e6 Hz (125 MHz) * 1ms
) (
    input clk,
    input rst,
    input error_seen,
    input comma_seen,
    input reset_done,
    output reg ready_out = 0,
    output reg [31:0] reset_out_cnt = 0,
    output reset_out
);
    // State encoding
    localparam  READY = 2'd0,
                RESET = 2'd1,
                CHECK = 2'd2;
    // State register
    (*mark_debug=DEBUG*) reg [1:0] state=CHECK;
    (*mark_debug=DEBUG*) reg [1:0] current_state=CHECK, next_state=CHECK;

    (*mark_debug=DEBUG*) reg [7:0] comma_cnt = 0;
    (*mark_debug=DEBUG*) reg [17:0] check_timeout_cnt=0; // time out counter to count up to 1ms (100e3)

    // Task to update state string for simulation only
    reg [8*7:1] state_string;
    task update_state_string;
        input [1:0] state;
        begin
            case (state)
                READY: state_string = "READY ";
                RESET: state_string = "RESET ";
                CHECK: state_string = "CHECK ";
                default: state_string = "UNKNOWN";
            endcase
        end
    endtask

    // State transition logic
    always @(posedge clk) begin
        if (rst) begin
            comma_cnt <= 8'd0;
            current_state <= CHECK;
        end else begin
            current_state <= next_state;
            if (current_state == RESET) begin
                comma_cnt <= 8'b0; // Reset comma counter in RESET state
                check_timeout_cnt <= 18'b0; // Reset timeout counter
            end else if (current_state == CHECK) begin
                if (comma_seen && comma_cnt < COMMAS_NEEDED) begin
                    comma_cnt <= comma_cnt + 1'd1;
                end
                if (check_timeout_cnt < CHECK_TIMEOUT) begin
                    check_timeout_cnt <= check_timeout_cnt + 1'd1;
                end
            end else begin
                check_timeout_cnt <= 18'b0; // Reset timeout counter in other states
            end
        end
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            READY: begin
                if (error_seen)
                    next_state = RESET;
                else
                    next_state = READY;
            end
            RESET: begin
                if (reset_done)
                    next_state = CHECK;
                else
                    next_state = RESET;
            end
            CHECK: begin
                if ((comma_cnt == COMMAS_NEEDED) && reset_done)
                    next_state = READY;
                else if (check_timeout_cnt == CHECK_TIMEOUT)
                    next_state = RESET;
                else
                    next_state = CHECK;
            end
            default: begin
                next_state = RESET;
            end
        endcase
    end

    reg reset=1'b0, reset_delay=1'b0;
    // Output logic
    always @(posedge clk) begin
        state <= current_state;
        update_state_string(current_state);
        reset_delay <= reset;
        reset <= (current_state == RESET);
        ready_out <= (current_state == READY);
        reset_out_cnt <= reset_out_cnt + reset_out;
    end
    assign reset_out = reset & ~reset_delay;   // Strobe reset_out for 1 cycle
endmodule


module gt_wrapper #(
    parameter GT_TYPE = "GTY"
) (
    // GT ports
    input wire         gt_refclk_p,
    input wire         gt_refclk_n,
    input wire         gt_rxp_in,
    input wire         gt_rxn_in,
    output wire        gt_refclk_out,
    // rx_usrclk domain
    output wire        rx_usrclk,
    output wire [15:0] rxdata_out,
    output wire [1:0]  rxdisperr_out,
    output wire [1:0]  rxnotintable_out,
    output wire [1:0]  rxcharisk_out,
    // sys_clk domain
    input wire         sys_clk,
    input wire         soft_reset,
    output wire        cplllocked_sys,
    output wire        rx_reset_done_sys
);
    wire gt_refclk;
    wire cplllocked;
    reg_tech_cdc cplllocked_x    (.I(cplllocked), .C(sys_clk), .O(cplllocked_sys));

    generate
        if (GT_TYPE=="GTY") begin : gty_inst
            wire gt_tx_clk;
            wire [15:0] txdata_in = 16'h00BC;
            wire gt_txp_out;    // not used
            wire gt_txn_out;    // not used
            wire reset_rx_done;  // in rx_usrclk
            wire reset_tx_done;  // in gt_tx_clk

            wire [15:0] rxctrl0, rxctrl1;
            wire  [7:0] rxctrl2, rxctrl3;
            assign rxcharisk_out = rxctrl0[1:0];
            assign rxdisperr_out = rxctrl1[1:0];
            assign rxnotintable_out = rxctrl3[1:0];

            wire gty_refclk_o2;
            IBUFDS_GTE4 #(
                .REFCLK_HROW_CK_SEL(2'b00)
            ) gty_refclk_ibufds (
                .I(gt_refclk_p),
                .IB(gt_refclk_n),
                .O(gt_refclk),
                .ODIV2(gty_refclk_o2)
            );

            BUFG_GT gty_refclk_bufgt (
                .I(gty_refclk_o2),
                .O(gt_refclk_out)
            );
            // create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name evr_gt
            // set_property -dict [list \
            //     CONFIG.TX_LINE_RATE {2.5} \
            //     CONFIG.TX_PLL_TYPE {CPLL} \
            //     CONFIG.TX_REFCLK_FREQUENCY {156.25} \
            //     CONFIG.TX_DATA_ENCODING {8B10B} \
            //     CONFIG.TX_USER_DATA_WIDTH {16} \
            //     CONFIG.TX_INT_DATA_WIDTH {20} \
            //     CONFIG.RX_LINE_RATE {2.5} \
            //     CONFIG.RX_PLL_TYPE {CPLL} \
            //     CONFIG.RX_REFCLK_FREQUENCY {156.25} \
            //     CONFIG.RX_DATA_DECODING {8B10B} \
            //     CONFIG.RX_USER_DATA_WIDTH {16} \
            //     CONFIG.RX_INT_DATA_WIDTH {20} \
            //     CONFIG.RX_BUFFER_MODE {0} \
            //     CONFIG.RX_JTOL_FC {1.4997001} \
            //     CONFIG.RX_REFCLK_SOURCE {X0Y4 clk1+2} \
            //     CONFIG.TX_REFCLK_SOURCE {X0Y4 clk1+2} \
            //     CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
            //     CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
            //     CONFIG.TXPROGDIV_FREQ_SOURCE {CPLL} \
            //     CONFIG.TXPROGDIV_FREQ_VAL {125} \
            //     CONFIG.FREERUN_FREQUENCY {100} \
            //     CONFIG.ENABLE_OPTIONAL_PORTS {cplllock_out} \
            // ] [get_ips evr_gt]
            // generate_target all [get_ips evr_gt]

            evr_gt evr_gty_i (
                .gtwiz_userclk_tx_reset_in      (1'b0),      // input wire [0 : 0] gtwiz_userclk_tx_reset_in
                .gtwiz_userclk_tx_srcclk_out    (),          // output wire [0 : 0] gtwiz_userclk_tx_srcclk_out
                .gtwiz_userclk_tx_usrclk_out    (),          // output wire [0 : 0] gtwiz_userclk_tx_usrclk_out
                .gtwiz_userclk_tx_usrclk2_out   (gt_tx_clk), // output wire [0 : 0] gtwiz_userclk_tx_usrclk2_out
                .gtwiz_userclk_tx_active_out    (),          // output wire [0 : 0] gtwiz_userclk_tx_active_out
                .gtwiz_userclk_rx_reset_in      (1'b0),      // input wire [0 : 0] gtwiz_userclk_rx_reset_in
                .gtwiz_userclk_rx_srcclk_out    (),          // output wire [0 : 0] gtwiz_userclk_rx_srcclk_out
                .gtwiz_userclk_rx_usrclk_out    (),          // output wire [0 : 0] gtwiz_userclk_rx_usrclk_out
                .gtwiz_userclk_rx_usrclk2_out   (rx_usrclk), // output wire [0 : 0] gtwiz_userclk_rx_usrclk2_out
                .gtwiz_userclk_rx_active_out    (),          // output wire [0 : 0] gtwiz_userclk_rx_active_out
                .gtwiz_buffbypass_rx_reset_in   (1'b0),      // input wire [0 : 0] gtwiz_buffbypass_rx_reset_in
                .gtwiz_buffbypass_rx_start_user_in(1'b0),    // input wire [0 : 0] gtwiz_buffbypass_rx_start_user_in
                .gtwiz_buffbypass_rx_done_out   (),          // output wire [0 : 0] gtwiz_buffbypass_rx_done_out
                .gtwiz_buffbypass_rx_error_out  (),          // output wire [0 : 0] gtwiz_buffbypass_rx_error_out
                .gtwiz_reset_clk_freerun_in     (sys_clk),   // input wire [0 : 0] gtwiz_reset_clk_freerun_in
                .gtwiz_reset_all_in             (soft_reset),     // input wire [0 : 0] gtwiz_reset_all_in
                .gtwiz_reset_tx_pll_and_datapath_in(1'b0),   // input wire [0 : 0] gtwiz_reset_tx_pll_and_datapath_in
                .gtwiz_reset_tx_datapath_in     (1'b0),      // input wire [0 : 0] gtwiz_reset_tx_datapath_in
                .gtwiz_reset_rx_pll_and_datapath_in(1'b0),   // input wire [0 : 0] gtwiz_reset_rx_pll_and_datapath_in
                .gtwiz_reset_rx_datapath_in     (1'b0),      // input wire [0 : 0] gtwiz_reset_rx_datapath_in
                .gtwiz_reset_rx_cdr_stable_out  (),          // output wire [0 : 0] gtwiz_reset_rx_cdr_stable_out
                .gtwiz_reset_tx_done_out        (reset_tx_done),     // output wire [0 : 0] gtwiz_reset_tx_done_out
                .gtwiz_reset_rx_done_out        (reset_rx_done),     // output wire [0 : 0] gtwiz_reset_rx_done_out
                .gtwiz_userdata_tx_in           (txdata_in),// input wire [15 : 0] gtwiz_userdata_tx_in
                .gtwiz_userdata_rx_out          (rxdata_out),   // output wire [15 : 0] gtwiz_userdata_rx_out
                .drpclk_in                      (sys_clk),   // input wire [0 : 0] drpclk_in
                .gtrefclk0_in                   (gt_refclk), // input wire [0 : 0] gtrefclk0_in
                .gtyrxn_in                      (gt_rxn_in), // input wire [0 : 0] gtyrxn_in
                .gtyrxp_in                      (gt_rxp_in), // input wire [0 : 0] gtyrxp_in
                .rx8b10ben_in                   (1'b1),      // input wire [0 : 0] rx8b10ben_in
                .tx8b10ben_in                   (1'b1),      // input wire [0 : 0] tx8b10ben_in
                .txctrl0_in                     (16'h0000),  // input wire [15 : 0] txctrl0_in
                .txctrl1_in                     (16'h0000),  // input wire [15 : 0] txctrl1_in
                .txctrl2_in                     (8'h01),     // input wire [7 : 0] txctrl2_in
                .cplllock_out                   (cplllocked),    // output wire [0 : 0] cplllock_out
                .gtpowergood_out                (),          // output wire [0 : 0] gtpowergood_out
                .gtytxn_out                     (gt_txn_out),// output wire [0 : 0] gtytxn_out
                .gtytxp_out                     (gt_txp_out),// output wire [0 : 0] gtytxp_out
                .rxctrl0_out                    (rxctrl0),   // output wire [15 : 0] rxctrl0_out
                .rxctrl1_out                    (rxctrl1),   // output wire [15 : 0] rxctrl1_out
                .rxctrl2_out                    (rxctrl2),   // output wire [7 : 0] rxctrl2_out
                .rxctrl3_out                    (rxctrl3),   // output wire [7 : 0] rxctrl3_out
                .rxpmaresetdone_out             (),          // output wire [0 : 0] rxpmaresetdone_out
                .txpmaresetdone_out             ()           // output wire [0 : 0] txpmaresetdone_out
            );
            reg_tech_cdc reset_rx_done_x (.I(reset_rx_done), .C(sys_clk), .O(rx_reset_done_sys));
        end else if (GT_TYPE=="GTX") begin : gtx_inst
            wire rx_outclk;

            IBUFDS_GTE2 refclk(
                .I(gt_refclk_p),
                .IB(gt_refclk_n),
                .CEB(1'b0),
                .O(gt_refclk)
            );
            assign gt_refclk_out = gt_refclk;
            BUFG rx_bufg (.I(rx_outclk), .O(rx_usrclk));

            evr_gt evr_gtx_i (
                .sysclk_in                  (sys_clk),      // input wire sysclk_in
                .soft_reset_rx_in           (soft_reset),// input wire soft_reset_rx_in
                .dont_reset_on_data_error_in(1'b1),         // input wire dont_reset_on_data_error_in
                .gt0_tx_fsm_reset_done_out  (),             // output wire gt0_tx_fsm_reset_done_out
                .gt0_rx_fsm_reset_done_out  (rx_reset_done_sys), // output wire gt0_rx_fsm_reset_done_out
                .gt0_data_valid_in          (1'b1),         // input wire gt0_data_valid_in

                //____________________________CHANNEL PORTS________________________________
                //------------------------------- CPLL Ports -------------------------------
                .gt0_cpllfbclklost_out   (),                // output wire gt0_cpllfbclklost_out
                .gt0_cplllock_out        (cplllocked),      // output wire gt0_cplllock_out
                .gt0_cplllockdetclk_in   (sys_clk),         // input wire gt0_cplllockdetclk_in
                .gt0_cpllreset_in        (1'b0),            // input wire gt0_cpllreset_in
                //------------------------ Channel - Clocking Ports ------------------------
                .gt0_gtrefclk0_in        (gt_refclk),       // input wire gt0_gtrefclk0_in
                .gt0_gtrefclk1_in        (1'b0),            // input wire gt0_gtrefclk1_in
                //-------------------------- Channel - DRP Ports  --------------------------
                .gt0_drpaddr_in          (9'd0),            // input wire [8:0] gt0_drpaddr_in
                .gt0_drpclk_in           (sys_clk),         // input wire gt0_drpclk_in
                .gt0_drpdi_in            (16'd0),           // input wire [15:0] gt0_drpdi_in
                .gt0_drpen_in            (1'b0),            // input wire gt0_drpen_in
                .gt0_drpwe_in            (1'b0),            // input wire gt0_drpwe_in
                //------------------------- Digital Monitor Ports --------------------------
                .gt0_dmonitorout_out     (),                // output wire [7:0] gt0_dmonitorout_out
                //------------------- RX Initialization and Reset Ports --------------------
                .gt0_eyescanreset_in     (1'b0),            // input wire gt0_eyescanreset_in
                .gt0_rxuserrdy_in        (1'b1),            // input wire gt0_rxuserrdy_in
                //------------------------ RX Margin Analysis Ports ------------------------
                .gt0_eyescandataerror_out(),                // output wire gt0_eyescandataerror_out
                .gt0_eyescantrigger_in   (1'b0),            // input wire gt0_eyescantrigger_in
                //---------------- Receive Ports - FPGA RX Interface Ports -----------------
                .gt0_rxdata_out          (rxdata_out),      // output wire [15:0] gt0_rxdata_out
                .gt0_rxusrclk_in         (rx_usrclk),       // input wire gt0_rxusrclk_in
                .gt0_rxusrclk2_in        (rx_usrclk),       // input wire gt0_rxusrclk2_in
                //---------------- Receive Ports - RX 8B/10B Decoder Ports -----------------
                .gt0_rxcharisk_out       (rxcharisk_out),   // output wire [1:0] gt0_rxcharisk_out
                .gt0_rxdisperr_out       (rxdisperr_out),   // output wire [1:0] gt0_rxdisperr_out
                .gt0_rxnotintable_out    (rxnotintable_out),// output wire [1:0] gt0_rxnotintable_out
                //------------------------- Receive Ports - RX AFE -------------------------
                .gt0_gtxrxp_in           (gt_rxp_in),     // input wire gt0_gtxrxp_in
                .gt0_gtxrxn_in           (gt_rxn_in),     // input wire gt0_gtxrxn_in
                //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
                .gt0_rxphmonitor_out     (),                // output wire [4:0] gt0_rxphmonitor_out
                .gt0_rxphslipmonitor_out (),                // output wire [4:0] gt0_rxphslipmonitor_out
                //------------------- Receive Ports - RX Equalizer Ports -------------------
                .gt0_rxdfelpmreset_in    (1'b0),            // input wire gt0_rxdfelpmreset_in
                .gt0_rxmonitorout_out    (),                // output wire [6:0] gt0_rxmonitorout_out
                .gt0_rxmonitorsel_in     (2'b01),           // input wire [1:0] gt0_rxmonitorsel_in
                //------------- Receive Ports - RX Fabric Output Control Ports -------------
                .gt0_rxoutclk_out        (rx_outclk),       // output wire gt0_rxoutclk_out
                .gt0_rxoutclkfabric_out  (),                // output wire gt0_rxoutclkfabric_out
                //----------- Receive Ports - RX Initialization and Reset Ports ------------
                .gt0_gtrxreset_in        (1'b0),            // input wire gt0_gtrxreset_in
                .gt0_rxpmareset_in       (1'b0),            // input wire gt0_rxpmareset_in
                //-------------------- Receive Ports - RX gearbox ports --------------------
                .gt0_rxslide_in          (1'b0),            // input wire gt0_rxslide_in
                //------------ Receive Ports -RX Initialization and Reset Ports ------------
                .gt0_rxresetdone_out     (),                // output wire gt0_rxresetdone_out
                //------------------- TX Initialization and Reset Ports --------------------
                .gt0_gttxreset_in        (1'b0),            // input wire gt0_gttxreset_in

                //____________________________COMMON PORTS________________________________
                .gt0_qplloutclk_in       (1'b0),            // input wire gt0_qplloutclk_in
                .gt0_qplloutrefclk_in    (1'b0)             // input wire gt0_qplloutrefclk_in
            );
        end else if (GT_TYPE=="GT_SIM") begin : gt_sim
            assign gt_refclk = gt_refclk_p;
            assign gt_refclk_out = gt_refclk;
            assign rx_usrclk = gt_refclk;
            // fake rx fsm reset mockup to simulate gty rx start up time
            reg [7:0] fake_fsm_cnt=8'd32;
            reg fake_fsm_active=0;
            assign rx_reset_done_sys = fake_fsm_cnt >= 8'd32;
            always @(posedge sys_clk) begin
                if (rx_reset_done_sys) fake_fsm_active <= 1'b0;
                if (soft_reset) begin
                    fake_fsm_active <= 1'b1;
                    fake_fsm_cnt <= 0;
                end
                if (fake_fsm_active)
                    fake_fsm_cnt <= fake_fsm_cnt + 1'd1;
            end
            assign rxnotintable_out = 2'b0;
            assign rxdisperr_out = 2'b0;
            assign rxdata_out = rx_reset_done_sys ? {8'h0, 8'hBC} : 0;
            assign rxcharisk_out = 2'b01;
            assign cplllocked_sys = 1'b1;
        end
    endgenerate
endmodule
