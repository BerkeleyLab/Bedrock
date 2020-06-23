#ifndef SETTINGS_H
#define SETTINGS_H
//-----------------------------
// Global settings file
//-----------------------------
// can be pretty much included by anyone (.S, .c, .h)
// Some of the constants here are expected by the startup script / library files
// and need to be defined even if not used

// Base addresses of Peripherals
#define BASE_BRAM              0x00000000
#define BASE_SRAM              0x01000000
#define BASE_GPIO              0x02000000
#define BASE_UART0             0x03000000
#define IRQ_UART0_RX           0x03

#define SRAM_SIZE               (1 << 19)  // [bytes]

#define F_CLK                  50000000     // [Hz] for CMODA7

#ifdef SIMULATION
    #define BOOTLOADER_DELAY    1
    #undef BOOTLOADER_BAUDRATE
    #define BOOTLOADER_BAUDRATE 9216000       // Used for fast simulation
#else
    #define BOOTLOADER_DELAY    (F_CLK/1000)  // How long to wait in the bootloader for a connection
#endif

#endif
