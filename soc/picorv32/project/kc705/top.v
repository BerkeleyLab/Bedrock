`timescale 1 ns / 1 ns

module top (
    input            SYSCLK_P,
    input            SYSCLK_N,
    output           UART_RTS,
    input            UART_CTS,
    input            CPU_RESET,

    output [7:0]     GPIO_LED,

    inout            I2C_SCL,
    inout            I2C_SDA,
    output           I2C_MUX_RESET_B,
    output           UART_TX,
    input            UART_RX,

    inout            LCD_DB4_LS,
    inout            LCD_DB5_LS,
    inout            LCD_DB6_LS,
    inout            LCD_DB7_LS,
    output           LCD_RW_LS,
    output           LCD_RS_LS,
    output           LCD_E_LS
);
assign UART_RTS = 1'b1;

wire pll_reset, sysclk_buf;
pb_debouncer debouncer_inst(
    .clk     (sysclk_buf),
    .PB      (CPU_RESET | UART_CTS),
    .PB_up   (pll_reset)
);

// Combine the 2 reset sources (USB, button)
wire clk, clk_200, locked;
xilinx7_clocks clk_inst(
    .sysclk_p (SYSCLK_P),
    .sysclk_n (SYSCLK_N),
    .sysclk_buf(sysclk_buf),
    .reset    (pll_reset),
    .clk_out0 (clk),
    .clk_out1 (clk_200),
    .locked   (locked)
);

wire [31:0] gpio_z;
system #(
    .SYSTEM_HEX_PATH ("./system32.hex")
)system_inst (
    .clk            (clk),
    .cpu_reset      (~locked),
    .gpio_z         (gpio_z),
    .uart_tx        (UART_TX),
    .uart_rx        (UART_RX),
    .trap           (trap)
);

// XXX gpio_z pinout must be matching settings.h
assign I2C_SDA          = gpio_z[0];
assign I2C_SCL          = gpio_z[1];
assign I2C_MUX_RESET_B  = gpio_z[2]; // to enable I2C mux, set high
assign LCD_DB4_LS       = gpio_z[8];
assign LCD_DB5_LS       = gpio_z[9];
assign LCD_DB6_LS       = gpio_z[10];
assign LCD_DB7_LS       = gpio_z[11];
assign LCD_RW_LS        = gpio_z[12];
assign LCD_RS_LS        = gpio_z[13];
assign LCD_E_LS         = gpio_z[14];

assign GPIO_LED = {trap, gpio_z[30:24]};

endmodule
