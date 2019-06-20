#ifndef SETTINGS_H
#define SETTINGS_H
//-----------------------------
// Global settings file
//-----------------------------
// can be pretty much included by anyone (.S, .c, .h)
// Some of the constants here are expected by the startup script / library files
// and need to be defined even if not used

// Base addresses of Peripherals
#define BASE_UART            0x08000000
#define BASE_DEBUG_UART      BASE_UART
#define F_CLK                100000000     // [Hz]

#endif
