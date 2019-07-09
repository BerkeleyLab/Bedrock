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
#define F_CLK                100000000     // [Hz] for CMODA7

#define PIN_PHY_RESET_B   2              // GPIO pin numbers
#define PIN_PHY_MDIO      1
#define PIN_PHY_MDC       0
#define MDIO_RESET_US     10
#define MDIO_DELAY_US     1              // > 400ns / 2

#endif
