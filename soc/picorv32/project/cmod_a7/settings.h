#ifndef SETTINGS_H
#define SETTINGS_H
//-----------------------------
// Global settings file
//-----------------------------
// can be pretty much included by anyone (.S, .c, .h)
// Some of the constants here are expected by the startup script / library files
// and need to be defined even if not used

// Base addresses of Peripherals
#define BASE_GPIO              0x01000000
#define BASE_UART0             0x02000000    // Debug UART connected to USB port on CMOD A7 board
#define BASE_DEBUG_UART        BASE_UART0

#define F_CLK                  100000000     // [Hz] for CMODA7

#ifdef SIMULATION
    #define BOOTLOADER_DELAY    1
    #define BOOTLOADER_BAUDRATE 9216000       // Used for fast simulation
#else
    #define BOOTLOADER_DELAY    (F_CLK/1000)  // How long to wait in the bootloader for a connection
    #define BOOTLOADER_BAUDRATE 115200        // Used for real hardware
#endif

#endif
