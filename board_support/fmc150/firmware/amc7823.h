//---------------------------------------
// ANALOG MONITORING AND CONTROL CIRCUIT
//---------------------------------------
// Controlled over SPI, used on FMC150

#ifndef AMC7823_H
#define AMC7823_H
#include <stdint.h>
#include "fmc150.h"
#include "settings.h"

#define AMC7823_SS_SET(val) SET_SFR1(BASE_FMC150_SFR, 0, PIN_AMC7823_NSS, val)

#define AMC7823_SPI_INIT() \
    SPI_INIT( (BASE_FMC150_SPI), 1, 1, 0, 1, 0, 16, 32 )

// reads all 9 ADC channels into uint16_t *retVal (size 9)
#define AMC7823_READ_ADC( retVal ) amc7823_read_regs( 0, 0x00, retVal, 9 )

// AMC7823 register names (some of them)
// All on page 1
#define AMC7823_DAC_CONFIG       0x09
#define AMC7823_AMC_CONFIG       0x0A
#define AMC7823_ADC_CONTROL      0x0B
#define AMC7823_RESET            0x0C
#define AMC7823_POWER_DOWN       0x0D
#define AMC7823_REVISION         0x1E

#define AMC7823_ADC_CH_AVDD_ADC     0
#define AMC7823_ADC_CH_3V3C         1
#define AMC7823_ADC_CH_1V8A         2
#define AMC7823_ADC_CH_1V8D         3
#define AMC7823_ADC_CH_12V          4
#define AMC7823_ADC_CH_3V3          5
#define AMC7823_ADC_CH_VADJ         6
#define AMC7823_ADC_CH_3V8          7

extern void     amc7823_read_regs( uint8_t page, uint8_t regAddr, uint16_t *buffer, uint8_t len );
extern void     amc7823_write_regs(uint8_t page, uint8_t regAddr, uint16_t *buffer, uint8_t len );
extern void     amc7823_write_reg( uint8_t page, uint8_t regAddr, uint16_t val );
extern uint16_t amc7823_read_reg(  uint8_t page, uint8_t regAddr );


#endif
