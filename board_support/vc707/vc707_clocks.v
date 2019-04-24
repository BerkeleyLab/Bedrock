module vc707_clocks #(
    parameter DIFF_CLKIN = "TRUE",
    parameter CLKIN_PERIOD = 5.0, // default 200MHz
    parameter MULT = 5,         // 200 X 5 = 1000
    parameter DIV0 = 10,        // 1000 / 10 = 100
    parameter DIV1 = 5          // 1000 / 5 = 200
) (
    input reset,
    input sysclk_p,
    input sysclk_n,
    output clk_out0,
    output clk_out1,
    output locked
);

wire sysclk_buf;

generate
    if (DIFF_CLKIN == "TRUE") begin : gen_ibufgds
        IBUFGDS ibufgds_int (
            .O(sysclk_buf),
            .I(sysclk_p),
            .IB(sysclk_n)
        );
    end else begin : gen_ibifg
        IBUF ibufgds_int (
            .O(sysclk_buf),
            .I(sysclk_p)
        );
    end
endgenerate

`ifndef SIMULATION

    wire mmcm_clkfbin;
    wire mmcm_clkfbout;
    wire clk_out0_int;
    wire clk_out1_int;
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
        .REF_JITTER1        (0.0)
    ) MMCME2_BASE_inst (
        .CLKOUT0            (clk_out0_int),
        .CLKOUT1            (clk_out1_int),
        .LOCKED             (locked),
        .CLKIN1             (sysclk_buf),
        .PWRDWN             (1'b0),
        .RST                (reset),
        .CLKFBIN            (mmcm_clkfbin),
        .CLKFBOUT           (mmcm_clkfbout)
    );

`else
    assign clk_out0 = sysclk_p;
`endif // `define SIMULATE

BUFG clkfbout_bufg (
    .O(mmcm_clkfbin),
    .I(mmcm_clkfbout)
);

BUFG clkout1_buf (
    .O   (clk_out0),
    .I   (clk_out0_int)
);

BUFG clkout2_buf (
    .O   (clk_out1),
    .I   (clk_out1_int)
);

endmodule
