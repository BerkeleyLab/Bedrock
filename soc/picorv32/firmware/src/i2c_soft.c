#include "i2c_soft.h"
#include <stdint.h>
#include "gpio.h"
#include "timer.h"
#include "settings.h"
#include "common.h"
#include "print.h"

//-------------------------------------------------
// Private macros /functions
//-------------------------------------------------
// setting / clearing / reading the I2C pins
#define SDA1() {SET_GPIO1(BASE_I2C, GPIO_OE_REG, PIN_I2C_SDA, 0); I2C_DELAY();}
#define SDA0() {SET_GPIO1(BASE_I2C, GPIO_OE_REG, PIN_I2C_SDA, 1); I2C_DELAY();}
#define SDAR()  GET_GPIO1(BASE_I2C, GPIO_IN_REG, PIN_I2C_SDA)
#define SCL1() {SET_GPIO1(BASE_I2C, GPIO_OE_REG, PIN_I2C_SCL, 0); I2C_DELAY();}
#define SCL0() {SET_GPIO1(BASE_I2C, GPIO_OE_REG, PIN_I2C_SCL, 1); I2C_DELAY();}
#define I2C_DELAY() DELAY_US(I2C_DELAY_US)

//-------------------------------------------------
// Low level functions
//-------------------------------------------------
void i2c_init(void)
{
    // I2C pin signals alternate between 0 and Z, so clear the gpioOut bits
    SET_GPIO1(BASE_I2C, GPIO_OUT_REG, PIN_I2C_SCL, 0);
    SET_GPIO1(BASE_I2C, GPIO_OUT_REG, PIN_I2C_SDA, 0);
    SDA1();
    SCL1();
}

void i2c_stop(void)
{
    SDA0();
    SCL1();
    SDA1();
}

void i2c_start(void)
{
    SCL1();
    SDA0();
    SCL0();
}

int i2c_tx(uint8_t dat)
{
    for (unsigned i=0; i<=7; i++) {
        if (dat & 0x80) {
            SDA1();
        } else {
            SDA0();
        }
        SCL1();
        dat <<= 1;
        SCL0();
    }
    // Receive ack
    SDA1();
    SCL1();
    int ack = SDAR() == 0;
    SCL0();
    return ack;
}

uint8_t i2c_rx(int ack)
{
    uint8_t dat = 0;
    // TODO check for clock stretching here
    for (unsigned i=0; i<=7; i++) {
        dat <<= 1;
        SCL1();
        dat |= SDAR();
        SCL0();
    }
    // Send ack
    SCL0();
    if (ack) {
        SDA0();
    } else {
        SDA1();
    }
    SCL1();
    SCL0();
    SDA1();
    return dat;
}

//-------------------------------------------------
// High level functions (dealing with registers)
//-------------------------------------------------
int i2c_write_regs(uint8_t i2cAddr, uint8_t regAddr, uint8_t *buffer, uint16_t len)
{
    int ret=1;
    i2c_start();
    ret &= i2c_tx((i2cAddr<<1) | I2C_W);
    ret &= i2c_tx(regAddr);
    while (len-- > 0)
        ret &= i2c_tx(*buffer++);
    i2c_stop();
    return ret;
}

int i2c_read_regs(uint8_t i2cAddr, uint8_t regAddr, uint8_t *buffer, uint16_t len)
{
    int ret=1;
    i2c_start();
    ret &= i2c_tx((i2cAddr<<1) | I2C_W);
    ret &= i2c_tx(regAddr);
    // Repeated start to switch to read mode
    i2c_start();
    ret &= i2c_tx((i2cAddr<<1) | I2C_R);
    while (len-- > 0)
        *buffer++ = i2c_rx(len!=0);   // Send NACK for the last byte
    i2c_stop();
    return ret;
}

//-------------------------------------------------
// Debugging functions (print stuff to uart)
//-------------------------------------------------
void i2c_scan(void)
{
    print_str("I2C scan: [");
    for (unsigned i=0; i<=127; i++) {
        i2c_start();
        int ret = i2c_tx((i<<1) | I2C_W);
        if(ret) {
            print_hex(i, 2);
            _putchar(' ');
        }
        i2c_stop();
    }
    print_str("]\n");
}

int i2c_dump(uint8_t i2cAddr, uint8_t regAddr, int nBytes)
{
    int ret=1;
    i2c_start();
    ret &= i2c_tx((i2cAddr<<1) | I2C_W);
    ret &= i2c_tx(regAddr);
    // Repeated start to switch to read mode
    i2c_start();
    ret &= i2c_tx((i2cAddr<<1) | I2C_R);
    if(!ret) {
        print_str("I2C Error\n");
        return ret;
    }
    for(int i=0; i<nBytes; i++) {
        if((nBytes>16) && ((i%16)==0)) {
            print_str("\n    ");
            print_hex(i+regAddr, 4);
            print_str(": ");
        }
        // Send NACK for the last byte
        print_hex(i2c_rx(i < (nBytes-1)), 2);
        print_str(" ");
    }
    i2c_stop();
    return ret;
}

int i2c_read_ascii(uint8_t i2cAddr, uint8_t regAddr, int nBytes)
{
    int ret=1;
    i2c_start();
    ret &= i2c_tx((i2cAddr<<1) | I2C_W);
    ret &= i2c_tx(regAddr);
    // Repeated start to switch to read mode
    i2c_start();
    ret &= i2c_tx((i2cAddr<<1) | I2C_R);
    while (nBytes-- > 0)
        _putchar(i2c_rx(nBytes!=0));   // Send NACK for the last byte
    i2c_stop();
    return ret;
}
