`timescale 1 ns / 1 ns

module system_top (
    input            SYSCLK,
    input [1:0]      BTNS,
    output [1:0]     LEDS,

    output           LED_B,
    output           LED_G,
    output           LED_R,

    input            UART_RXD,
    output           UART_TXD,

   // SRAM Hardware interface
    inout  [ 7:0] MemDB,
    output [18:0] MemAdr,
    output        RamOEn,
    output        RamWEn,
    output        RamCEn
);

wire pll_reset, sysclk_buf;
pb_debouncer debouncer_inst(
    .clk     (sysclk_buf),
    .PB      (|BTNS),
    .PB_up   (pll_reset)
);

wire clk, locked;
xilinx7_clocks #(
    .DIFF_CLKIN     ("FALSE"),  // Single ended
    .CLKIN_PERIOD   (83.333),   // 12 MHz
    .MULT           (62.500),   // 750 MHz
    .DIV0           (9),        // 83.3 MHz
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
system #(
    .SYSTEM_HEX_PATH ("system32.dat")
) system_inst (
    .clk        (clk),
    .cpu_reset  (~locked),

    .uart_tx0   (UART_TXD),
    .uart_rx0   (UART_RXD),

    .gpio_z     (gpio_z),

    // SRAM Hardware interface
    .ram_data_z  (MemDB),
    .ram_address (MemAdr),
    .ram_nce     (RamCEn),
    .ram_noe     (RamOEn),
    .ram_nwe     (RamWEn)
);

assign LEDS[1:0] = gpio_z[7:6];
assign {LED_B, LED_G, LED_R} = gpio_z[2:0];

endmodule
