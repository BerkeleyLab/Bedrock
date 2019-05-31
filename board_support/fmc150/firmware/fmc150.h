// Expects the following decelerations in settings.h:
// #define BASE_FMC150            0x03000000

#ifndef FMC150_H
#define FMC150_H

#include <stdint.h>
#include <stdbool.h>
// Base addresses of internal packed modules
#define BASE_FMC150_SFR      (BASE_FMC150+(0x00<<16))
#define BASE_FMC150_SPI      (BASE_FMC150+(0x01<<16))
#define BASE_FMC150_ADC_IDEL (BASE_FMC150+(0x02<<16))
#define BASE_FMC150_ADC_FCNT (BASE_FMC150+(0x03<<16))
#define BASE_FMC150_DAC      (BASE_FMC150+(0x04<<16))

// Pin definition of fmc150.v internal SFR
#define PIN_CDCE72010_NRST   0
#define PIN_ADS62P49_RST     1
#define PIN_AMC7823_NRST     2
#define PIN_CDCE72010_NPDWN  3
#define PIN_CDCE72010_NSS    8
#define PIN_ADS62P49_NSS     9
#define PIN_DAC3283_NSS      10
#define PIN_DAC3283_TXEN     11
#define PIN_AMC7823_NSS      12
#define PIN_FMC150_REF_EN    13
#define PIN_FMC150_PG_C2M    14
#define PIN_PRSNT_M2C_L      15
#define PIN_PLL_STATUS       16

typedef enum {
    FMC150_DEV_ILLEGAL,   // Fake device, end of init script marker
    FMC150_DEV_ADS62P49,  // SPI
    FMC150_DEV_AMC7823,   // SPI
    FMC150_DEV_CDCE72010, // SPI
    FMC150_DEV_DAC3283,   // SPI
    FMC150_DEV_LOCAL      // control pins / fpga internal stuff
} t_deviceId;

typedef struct {
    t_deviceId  deviceId;
    uint8_t     regAddr;
    uint32_t    val;
} t_cfgReg;

// Return values for error handling
typedef enum{
    RET_OK,
    RET_UNKNOWN,
    RET_ERR,
    RET_ERR_SPI,
    RET_ERR_ADC_IDEL,
    RET_ERR_DAC_TP,
    RET_ERR_DAC_CLK,
    RET_ERR_DAC_FIFO,
    RET_ERR_DAC_UNLOCKED,
    RET_ERR_NO_FMC
} t_fmc150Error;

//---------------------------------
// registers for FMC150_DEV_LOCAL
//---------------------------------
#define LOC_ADC_PRINT  0x00  // trigger print of the IDELAY eye diagram 0=chA/1=chB
#define LOC_ADC_ALIGN  0x01  // trigger IDELAY alignment
#define LOC_DAC_TXEN   0x05  // enable DAC analog out 1/0
#define LOC_DAC_TPCHK  0x06  // trigger DAC resync and test pattern check
#define LOC_DAC_ALCHK  0x07  // check DAC clk alarm flags
#define LOC_CDC_POWER  0x08  // enable CDCE power 1/0
#define LOC_CDC_REF    0x09  // enable 100 MHz reference 1/0
#define LOC_FMC_RST    0x0A  // trigger init of all pins and reset all chips

// Plays back an array of t_cfgReg and sends initialization data
// to the chips
// *reg points to an array of t_cfgReg items
// stops on deviceId == DEV_ILLEGAL
// returns true on success
bool init_fmc150( const t_cfgReg *reg );

// Gets called when an error happens
// Can be overridden by the user
// Default implementation just prints to UART
// Return true to continue further initialization steps
// Return false to abort initialization
extern bool __attribute__((weak)) errorHook( t_fmc150Error errValue );

#endif
