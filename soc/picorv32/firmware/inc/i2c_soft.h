//-------------------------------------------------
// I2C bit-bang library
//-------------------------------------------------
// Expects the following macros in settings.h:
// #define PIN_I2C_SDA              0  // GPIO pin number of the data pin
// #define PIN_I2C_SCL              1  // GPIO pin number of the clock pin
// #define I2C_DELAY_US             1  //~half a clock period [us]
// #define BASE_GPIO       0x01000000  //base address of the gpio module used for soft_i2c

#ifndef I2C_SOFT_H
#define I2C_SOFT_H

#include <stdint.h>

#define I2C_R                1
#define I2C_W                0
#define I2C_ACK              1
#define I2C_NACK             0

//-------------------------------------------------
// Low level functions (doing I2C things)
//-------------------------------------------------
void i2c_init(void);                // initialize GPIO pins
void i2c_stop(void);                // Send I2C start-condition
void i2c_start(void);               // Send I2C stop-condition
int i2c_tx( uint8_t dat );  // sends out 8 bits (dat), returns ack (9th bit, 1 = ack ok)
uint8_t i2c_rx( int ack );  // reads & returns 8 bit, sends ack

//-------------------------------------------------
// High level functions (dealing with registers)
//-------------------------------------------------
// Typical register based writing (write regAddr, then write data)
// i2cAddr = 7 bit I2C address. MSB = 0.
// returns 1 on success, 0 if one or more ACK bits were missing
int i2c_write_regs( uint8_t i2cAddr, uint8_t regAddr, uint8_t *buffer, uint16_t len );

// Typical register based reading (write regAddr, then read data)
// i2cAddr = 7 bit I2C address. MSB = 0.
// returns 1 on success, 0 if one or more ACK bits were missing
int i2c_read_regs( uint8_t i2cAddr, uint8_t regAddr, uint8_t *buffer, uint16_t len );

//-------------------------------------------------
// Debugging functions (printing stuff)
//-------------------------------------------------
// Scan through all I2C addresses, try to write and
// reports the ones which respond with an ack
void i2c_scan(void);

// Read data over I2C and print it as a hex-dump to UART
// i2cAddr= 7 bit i2c slave address
// regAddr= register offset
// nBytes = number of bytes to read
int i2c_dump( uint8_t i2cAddr, uint8_t regAddr, int nBytes );

// Read data over I2C and directly print it as characters to UART
// adr    = 7 bit i2c slave address
// regAddr= register offset
// nBytes = number of bytes to read
int i2c_read_ascii( uint8_t i2cAddr, uint8_t regAddr, int nBytes );

#endif
