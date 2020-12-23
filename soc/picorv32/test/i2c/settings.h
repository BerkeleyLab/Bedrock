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

// I2C specific settings
#define BASE_I2C             BASE_GPIO
#define PIN_I2C_SDA          1              // GPIO pin numbers
#define PIN_I2C_SCL          0
#define I2C_DELAY_US         1              //~half a clock period [us]

#endif
