//-------------------------------------------------
// Onewire bit-bang library
//-------------------------------------------------
// Expects the following macros in settings.h:
// #define PIN_I2C_SDA              0  // GPIO pin number of the data pin
// #define PIN_I2C_SCL              1  // GPIO pin number of the clock pin
// #define I2C_DELAY_US             1  //~half a clock period [us]
// #define BASE_GPIO       0x01000000  //base address of the gpio module used for soft_i2c

#ifndef ONEWIRE_SOFT_H
#define ONEWIRE_SOFT_H

#include <stdint.h>

//-------------------------------------------------
// Low level functions
//-------------------------------------------------
void onewire_init(void);            // initialize GPIO pins
int onewire_reset(void);            // reset bus with long low-going pulse, return "presence"
int onewire_tx( uint8_t dat );      // sends out 8 bits (dat), returns ack (9th bit, 1 = ack ok)

//-------------------------------------------------
// High level functions (dealing with registers)
//-------------------------------------------------
// Typical register based writing (write regAddr, then write data)
// i2cAddr = 7 bit I2C address. MSB = 0.
// returns 1 on success, 0 if one or more ACK bits were missing
int onewire_write_regs( uint8_t i2cAddr, uint8_t regAddr, uint8_t *buffer, uint16_t len );

// Typical register based reading (write regAddr, then read data)
// i2cAddr = 7 bit I2C address. MSB = 0.
// returns 1 on success, 0 if one or more ACK bits were missing
int onewire_read_regs( uint8_t i2cAddr, uint8_t regAddr, uint8_t *buffer, uint16_t len );

//-------------------------------------------------
// Debugging functions (printing stuff)
//-------------------------------------------------
// Scan through all addresses, try to write and
// reports the ones which respond with an ack
void onewire_scan(void);

int onewire_dump( uint8_t i2cAddr, uint8_t regAddr, int nBytes );

int onewire_read_ascii( uint8_t i2cAddr, uint8_t regAddr, int nBytes );

#endif
