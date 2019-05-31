// --------------------------------------------------------------
//  idelay_wrap.v
// --------------------------------------------------------------
// helper block to handle the delay of one lane of a DDR LVDS interface
// (as used for example in the ADS62P49 ADC)
//
// processing chain:
// in_p, in_n
//     ||
// [ibufds  ]  symmetric to single ended
//     |
// [idelaye2]  variable delay (5 bit)
//     |
// out_del

module idelay_wrap #(
    parameter IDELAY_VALUE=0,
    parameter REFCLK_FREQUENCY=200.0
) (
    // LVDS interface
    input        in_p,
    input        in_n,
    output       out_del,
    // Control interface
    input        clk,
    input        rst,
    input        del_ld,    // pulse to latch new delay value
    input  [4:0] del_cnt_wr,// set delay value (0-31)
    output [4:0] del_cnt_rd // read current delay value
);

`ifdef SIMULATION
    assign del_cnt_rd = del_cnt_wr;
    assign out_del = in_p;
`else
    // Differential input buffer
    wire sig_ddr;
    IBUFDS #(
        .DIFF_TERM ("TRUE")
    ) ibufds_inst (
        .I         (in_p),
        .IB        (in_n),
        .O         (sig_ddr)
    );

    // IDELAYE2 Variable Delay Element
    IDELAYE2 #(
        .CINVCTRL_SEL         ("FALSE"    ),// Enable dynamic clock inversion ("TRUE"/"FALSE")
        .DELAY_SRC            ("IDATAIN"  ),// Delay input ("IDATAIN" or "DATAIN")
        .HIGH_PERFORMANCE_MODE("TRUE"     ),// Reduced jitter ("TRUE"), Reduced power ("FALSE")
        .IDELAY_TYPE          ("VAR_LOAD" ),// "FIXED", "VARIABLE", "VAR_LOAD" or "VAR_LOAD_PIPE"
        .IDELAY_VALUE         (IDELAY_VALUE),// Initial delay tap setting (0-31)
        .REFCLK_FREQUENCY     (REFCLK_FREQUENCY),// IDELAYCTRL clock input frequency in MHz
        .SIGNAL_PATTERN       ("DATA"     ),// "DATA" or "CLOCK" input signal
        .PIPE_SEL             ("FALSE"    ) // Select pipelined mode, "TRUE"/"FALSE"
    ) idelaye2_inst (
        .CNTVALUEOUT          (del_cnt_rd ),// Counter value for monitoring purpose
        .DATAOUT              (out_del    ),// Delayed data output
        .C                    (clk        ),// Clock input
        .CE                   (1'b0       ),// Active high enable increment/decrement function
        .CINVCTRL             (1'b0       ),// Dynamically inverts the Clock (C) polarity
        .CNTVALUEIN           (del_cnt_wr ),// Counter value for loadable counter application
        .DATAIN               (1'b0       ),// fabric-style input
        .IDATAIN              (sig_ddr    ),// IOB-style input
        .INC                  (1'b0       ),// Increment / Decrement tap delay
        .REGRST               (rst        ),// Active high, synchronous reset,
        // resets delay chain to IDELAY_VALUE tap. If no value is specified, the default is 0.
        .LD                   (del_ld     ),// Load IDELAY_VALUE input
        .LDPIPEEN             (1'b0       ) // Enable PIPELINE register to load data input
    );

    // (* IODELAY_GROUP = "lvds_in_delay" *)
    // IDELAYCTRL idelayctrl_inst (
    //   .RST          (rst        ),
    //   .REFCLK       (clk        ),
    //   .RDY          (           )
    // );
`endif

endmodule
