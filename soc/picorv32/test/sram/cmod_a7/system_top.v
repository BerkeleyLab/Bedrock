`timescale 1 ns / 1 ns
module system_top (
    input            sysclk,
    input [1:0]      btn,
    output [1:0]     led,

    // debug uart
    output           uart_rxd_out,
    input            uart_txd_in,

    // SRAM Hardware interface
    inout  [ 7:0] MemDB,
    output [18:0] MemAdr,
    output        RamOEn,
    output        RamWEn,
    output        RamCEn
);

wire clk, locked;
xilinx7_clocks #(
    .DIFF_CLKIN     ("FALSE"),  // Single ended
    .CLKIN_PERIOD   (83.333),   // 12 MHz
    .MULT           (62.500),   // 750 MHz
    .DIV0           (10),       // 10 = 75 MHz, memtest fails when going any faster
    .DIV1           (7.500)     // 100 MHz
) clk_inst(
    .sysclk_p (sysclk),
    .sysclk_n (1'b0),
    .sysclk_buf(sysclk_buf),
    .reset    (1'b0),
    .clk_out0 (clk),
    .clk_out1 (),
    .locked   (locked)
);

wire trap;
system #(
    .SYSTEM_HEX_PATH("/home/michael/fpga_wsp/bedrock/soc/picorv32/test/sram/cmod_a7/system_top32.hex")
    ) sys_inst (
    .clk        (clk),
    .reset      (~locked),
    .trap       (trap),

    .uart_tx0   (uart_rxd_out),
    .uart_rx0   (uart_txd_in),

    // SRAM Hardware interface
    .ram_data_z  (MemDB),
    .ram_address (MemAdr),
    .ram_nce     (RamCEn),
    .ram_noe     (RamOEn),
    .ram_nwe     (RamWEn)
);

assign led = {trap, trap};
endmodule
