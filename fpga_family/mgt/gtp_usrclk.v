// Generate 125MHz GMII clk from GTP 62.5MHz tx/rx clk output
//    UG472 Fig 3-11
`timescale 1ns / 1ns

module gtp_usrclk (
    input gtp_clk,
    output gtp_clk_90,
    output gmii_clk,
    output pll_lock
);

`ifndef SIMULATE
// Input Buffering
//wire gtp_clk_ibuf;
//IBUF clkin1_ibuf (
//    .I(gtp_clk),
//    .O(gtp_clk_ibuf)
//);

wire clkfbout_int, clkfbout_buf;
wire clkout0_int, clkout1_int;

MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"), // Jitter programming (OPTIMIZED, HIGH, LOW)
    .CLKFBOUT_MULT_F(16.0), // Multiply value for all CLKOUT (2.000-64.000).
    .CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
    .CLKIN1_PERIOD(16.0), // 62.5MHz
    // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
    .CLKOUT1_DIVIDE(8),
    .CLKOUT0_DIVIDE_F(16.0), // Divide amount for CLKOUT0 (1.000-128.000).
    // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT1_DUTY_CYCLE(0.5),
    // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
    .CLKOUT0_PHASE(90.0),
    .CLKOUT1_PHASE(0.0),
    .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
    .DIVCLK_DIVIDE(1), // Master division value (1-106)
    .REF_JITTER1(0.0), // Reference input jitter in UI (0.000-0.999).
    .STARTUP_WAIT("FALSE") // Delays DONE until MMCM is locked (FALSE, TRUE)
) MMCME2_BASE_inst (
    // Clock Outputs: 1-bit (each) output: User configurable clock outputs
    .CLKOUT0(clkout0_int), // 1-bit output: CLKOUT0
    .CLKOUT0B(), // 1-bit output: Inverted CLKOUT0
    .CLKOUT1(clkout1_int), // 1-bit output: CLKOUT1
    .CLKOUT1B(), // 1-bit output: Inverted CLKOUT1
    // Feedback Clocks: 1-bit (each) output: Clock feedback ports
    .CLKFBOUT(clkfbout_int), // 1-bit output: Feedback clock
    .CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
    // Status Ports: 1-bit (each) output: MMCM status ports
    .LOCKED(pll_lock), // 1-bit output: LOCK
    // Clock Inputs: 1-bit (each) input: Clock input
    .CLKIN1(gtp_clk), // 1-bit input: Clock
    // Control Ports: 1-bit (each) input: MMCM control ports
    .PWRDWN(1'b0), // 1-bit input: Power-down
    .RST(1'b0), // 1-bit input: Reset
    // Feedback Clocks: 1-bit (each) input: Clock feedback ports
    .CLKFBIN(clkfbout_buf) // 1-bit input: Feedback clock
);

BUFG clkfbout_bufg (
    .O(clkfbout_buf),
    .I(clkfbout_int)
);

BUFG clkout0_bufg (
    .O(gtp_clk_90),
    .I(clkout0_int)
);

BUFG clkout1_bufg (
    .O(gmii_clk),
    .I(clkout1_int)
);
`else
reg clk_r=0;
always begin #4; clk_r = ~clk_r; end
assign gmii_clk = clk_r;
`endif // `ifndef SIMULATE
endmodule
