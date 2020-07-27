#ifndef SETTINGS_H
#define SETTINGS_H
//-----------------------------
// Global settings file
//-----------------------------
// can be pretty much included by anyone (.S, .c, .h)
// Some of the constants here are expected by the startup script / library files
// and need to be defined even if not used

// Base addresses of Peripherals
#define BASE_BRAM               0x00000000
#define BASE_SRAM               0x01000000
#define BASE_GPIO               0x02000000
#define BASE_UART0              0x03000000
#define BASE_MEMIO              0x04000000

#define IRQ_UART0_RX            0x03

#define SRAM_SIZE               (1 << 19)  // [bytes]

#define F_CLK                   (1200000 * 625 / 9)  // 83.3 MHz

// How long to wait in the bootloader for a connection
#define BOOTLOADER_DELAY        (F_CLK / 1000)

#endif
