`timescale 1 ns / 1 ns

module system_top (
    input            SYSCLK,
    inout [7:0]      Pmod1,

    input            UART_RXD,
    output           UART_TXD,

    output        qspi_cs,
    inout [3:0]   qspi_dq,
    // Note that unless someone accidentally installed
    // R209 and R210, QSPI mode won't work

    output        VCXO_EN
);

wire pll_reset, sysclk_buf;
pb_debouncer debouncer_inst(
    .clk     (sysclk_buf),
    .PB      (Pmod1[0]),
    .PB_up   (pll_reset)
);

assign VCXO_EN = 1;  // Need to turn this on, on we get no clock!

wire clk, locked;
xilinx7_clocks #(
    .DIFF_CLKIN     ("FALSE"),  // Single ended
    .CLKIN_PERIOD   (50.00),    // 20 MHz
    .MULT           (37.50),    // 750 MHz
    .DIV0           (11),       // 68.2 MHz
    .DIV1           (7.500)     // 100 MHz
) clk_inst(
    .sysclk_p (SYSCLK),
    .sysclk_n (1'b0),
    .sysclk_buf(sysclk_buf),
    .reset    (pll_reset),
    .clk_out0 (clk),
    .clk_out1 (),
    .locked   (locked)
);

wire [31:0] gpio_z;

wire       flash_clk;

STARTUPE2 SUP_INST (
    .CLK        (0),
    .GSR        (0),
    .GTS        (0),
    .KEYCLEARB  (0),
    .PACK       (1),
    .USRCCLKO   (flash_clk),
    .USRCCLKTS  (0),
    .USRDONEO   (1),
    .USRDONETS  (0)
);

system #(
    .SYSTEM_HEX_PATH ("system32.dat")
) system_inst (
    .clk        (clk),
    .cpu_reset  (~locked),

    .uart_tx0   (UART_TXD),
    .uart_rx0   (UART_RXD),

    .gpio_z     (gpio_z),

    // SPI flash Hardware interface
    .flash_csb  (qspi_cs),
    .flash_clk  (flash_clk),
    .flash_dz   (qspi_dq)
);

assign Pmod1[7:1] = gpio_z[7:1];

endmodule
