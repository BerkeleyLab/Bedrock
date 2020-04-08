#ifndef SETTINGS_H
#define SETTINGS_H
//-----------------------------
// Global settings file
//-----------------------------
// can be pretty much included by anyone (.S, .c, .h)
// Some of the constants here are expected by the startup script / library files
// and need to be defined even if not used

// #define F_CLK           125000000      // [Hz]
#define F_CLK           1250000      // [Hz]

// Base addresses of Peripherals
#define BASE_BADGER     0x01000000
#define BASE_CONSOLE    0x03000000

#endif
