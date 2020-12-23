module xilinx7_clocks #(
    parameter DIFF_CLKIN = "TRUE",
    parameter CLKIN_PERIOD = 5.0, // default 200MHz
    parameter MULT = 5,         // 200 X 5 = 1000
    parameter DIV0 = 8,         // 1000 / 8 = 125
    parameter DIV1 = 5          // 1000 / 5 = 200
) (
    input reset,
    input sysclk_p,
    input sysclk_n,
    output sysclk_buf,
    output clk_out0,
    output clk_out1,
    output clk_out2,
    output clk_out3f,
    output locked
);

generate
    if (DIFF_CLKIN == "TRUE") begin : gen_ibufgds
        IBUFGDS ibufgds_int (
            .O(sysclk_buf),
            .I(sysclk_p),
            .IB(sysclk_n)
        );
    end else if (DIFF_CLKIN == "BYPASS") begin : gen_bypass
        assign sysclk_buf = sysclk_p;
    end else begin : gen_ibifg
        IBUF ibufgds_int (
            .O(sysclk_buf),
            .I(sysclk_p)
        );
    end
endgenerate

wire mmcm_clkfbin;
wire mmcm_clkfbout;
wire clk_out0_int;
wire clk_out1_int;
wire clk_out2_int;

MMCME2_BASE #(
    .BANDWIDTH          ("OPTIMIZED"),
    .CLKOUT4_CASCADE    ("FALSE"),
    .STARTUP_WAIT       ("FALSE"),
    .DIVCLK_DIVIDE      (1),
    .CLKFBOUT_MULT_F    (MULT),
    .CLKFBOUT_PHASE     (0.0),
    .CLKIN1_PERIOD      (CLKIN_PERIOD),
    .CLKOUT0_DIVIDE_F   (DIV0),
    .CLKOUT0_DUTY_CYCLE (0.5),
    .CLKOUT0_PHASE      (0.0),
    .CLKOUT1_DIVIDE     (DIV1),
    .CLKOUT1_DUTY_CYCLE (0.5),
    .CLKOUT1_PHASE      (0.0),
    // CLKOUT2 just like CLKOUT0 but 90 degrees shifted
    .CLKOUT2_DIVIDE     (DIV0),
    .CLKOUT2_DUTY_CYCLE (0.5),
    .CLKOUT2_PHASE      (90.0),
    // CLKOUT3 for high-speed testing
    .CLKOUT3_DIVIDE     (4),
    .REF_JITTER1        (0.01)
) MMCME2_BASE_inst (
    .CLKOUT0            (clk_out0_int),
    .CLKOUT1            (clk_out1_int),
    .CLKOUT2            (clk_out2_int),
    .CLKOUT3            (clk_out3f),
    .LOCKED             (locked),
    .CLKIN1             (sysclk_buf),
    .PWRDWN             (1'b0),
    .RST                (reset),
    .CLKFBIN            (mmcm_clkfbin),
    .CLKFBOUT           (mmcm_clkfbout)
);

BUFG clkfbout_bufg (
    .O(mmcm_clkfbin),
    .I(mmcm_clkfbout)
);

BUFG clkout0_buf (
    .O   (clk_out0),
    .I   (clk_out0_int)
);

BUFG clkout1_buf (
    .O   (clk_out1),
    .I   (clk_out1_int)
);

BUFG clkout2_buf (
    .O   (clk_out2),
    .I   (clk_out2_int)
);

endmodule
