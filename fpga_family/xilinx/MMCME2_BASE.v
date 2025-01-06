// !!! Placeholder only !!!

// verilator lint_save
// verilator lint_off UNDRIVEN

module MMCME2_BASE #(
    parameter BANDWIDTH = "OPTIMIZED",
    parameter real CLKFBOUT_MULT_F = 5.000,
    parameter real CLKFBOUT_PHASE = 0.000,
    parameter real CLKIN1_PERIOD = 0.000,
    parameter real CLKOUT0_DIVIDE_F = 1.000,
    parameter real CLKOUT0_DUTY_CYCLE = 0.500,
    parameter real CLKOUT0_PHASE = 0.000,
    parameter integer CLKOUT1_DIVIDE = 1,
    parameter real CLKOUT1_DUTY_CYCLE = 0.500,
    parameter real CLKOUT1_PHASE = 0.000,
    parameter integer CLKOUT2_DIVIDE = 1,
    parameter real CLKOUT2_DUTY_CYCLE = 0.500,
    parameter real CLKOUT2_PHASE = 0.000,
    parameter integer CLKOUT3_DIVIDE = 1,
    parameter real CLKOUT3_DUTY_CYCLE = 0.500,
    parameter real CLKOUT3_PHASE = 0.000,
    parameter CLKOUT4_CASCADE = "FALSE",
    parameter integer CLKOUT4_DIVIDE = 1,
    parameter real CLKOUT4_DUTY_CYCLE = 0.500,
    parameter real CLKOUT4_PHASE = 0.000,
    parameter integer CLKOUT5_DIVIDE = 1,
    parameter real CLKOUT5_DUTY_CYCLE = 0.500,
    parameter real CLKOUT5_PHASE = 0.000,
    parameter integer CLKOUT6_DIVIDE = 1,
    parameter real CLKOUT6_DUTY_CYCLE = 0.500,
    parameter real CLKOUT6_PHASE = 0.000,
    parameter integer DIVCLK_DIVIDE = 1,
    parameter real REF_JITTER1 = 0.010,
    parameter STARTUP_WAIT = "FALSE"
)(
    output  CLKFBOUT,
    output  CLKFBOUTB,
    output  CLKOUT0,
    output  CLKOUT0B,
    output  CLKOUT1,
    output  CLKOUT1B,
    output  CLKOUT2,
    output  CLKOUT2B,
    output  CLKOUT3,
    output  CLKOUT3B,
    output  CLKOUT4,
    output  CLKOUT5,
    output  CLKOUT6,
    output  LOCKED,
    input   CLKFBIN,
    input   CLKIN1,
    input   PWRDWN,
    input   RST
);

assign CLKOUT0 = CLKIN1;
assign CLKOUT1 = CLKIN1;
assign LOCKED = 1;
// verilator lint_restore

endmodule // MMCME2_BASE
