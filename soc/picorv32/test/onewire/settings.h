#ifndef SETTINGS_H
#define SETTINGS_H
//-----------------------------
// Global settings file
//-----------------------------
// can be pretty much included by anyone (.S, .c, .h)
// Some of the constants here are expected by the startup script / library files
// and need to be defined even if not used

// Base addresses of Peripherals
#define BASE_GPIO            0x01000000
#define BASE_UART0           0x02000000
#define BASE_DEBUG_UART      BASE_UART0
#define F_CLK                5000000     // [Hz] absurdly slow to make simulations faster

// One-wire specific settings
#define BASE_ONEWIRE         BASE_GPIO
#define PIN_ONEWIRE_A        3              // GPIO pin numbers
#define PIN_ONEWIRE_B        4

#endif
