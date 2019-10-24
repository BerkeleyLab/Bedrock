// Dual Channel 14-/12-Bit, 250-/210-MSPS ADC
// With DDR LVDS and Parallel CMOS Outputs
// Controlled over SPI, used on FMC150

#ifndef ADS62P49_H
#define ADS62P49_H
#include "fmc150.h"
#include "settings.h"

// Must be called before each READ / WRITE
// Deal with 16 bit words
#define ADS62P49_SPI_INIT() \
    SPI_INIT( (BASE_FMC150_SPI), 0, 0, 1, 0, 0, 16, 32 )

#define ADS62P49_SS_SET(val) \
    SET_SFR1(BASE_FMC150_SFR, 0, PIN_ADS62P49_NSS, val)

// 8 bit regAddr,  8 bit val
void ads62p49_write_reg( uint8_t regAddr, uint8_t val );

// 8 bit regAddr, returns 8 bit val
uint8_t ads62p49_read_reg( uint8_t regAddr );

// Return received test-pattern (14 bit)
// Select from 2 ADC channels and 2 subsequent clock cycles
// ch: 0=chA, 1=chB;  smpl: 0=clk, 1=clk+1;
#define ADS62P49_GET_SAMPLES( ch, smpl ) GET_REG16( \
    BASE_FMC150_ADC_FCNT + ((smpl)?4:0) + ((ch)?2:0)\
)

// Get frequency of AB clock.
// To print in MHz: print_udec_fix( ADS62P49_GET_F_AB()*125, 24, 3 );
// Where the reference clock is at 125 MHz
#define ADS62P49_GET_F_AB() GET_REG(BASE_FMC150_ADC_FCNT+2*4)

// Set the tap-delay value of an LVDS input lane
// id = 0..13,  val = 0..31
#define ADS62P49_SET_IDELAY( id, val ) SET_REG16(BASE_FMC150_ADC_IDEL, ((val)<<8)|(id) )

// Write the tap-delay value of an LVDS input lane into val
#define ADS62P49_GET_IDELAY( id, val ) {    \
    SET_REG8(BASE_FMC150_ADC_IDEL, id );    \
    val = GET_REG8(BASE_FMC150_ADC_IDEL+1); \
}

//---------------------------------
// Test pattern settings
//---------------------------------
// pattern value (reg 0x52, reg 0x51)
#define ADS_TP_VAL      0x1555
// #define ADS_TP_VAL      0x2aaa
// Test pattern select (reg 0x62)
#define ADS_TP_OFF      0  //normal operation
#define ADS_TP_ZEROS    1  //all zeros
#define ADS_TP_ONES     2  //all ones
#define ADS_TP_TOGGLE   3  //toggle pattern (0x1555 / 0x2aaa)
#define ADS_TP_RAMP     4  //digital ramp
#define ADS_TP_REGVAL   5  //custom value (from reg {0x52,0x51})

//---------------------------------
// Clock phase settings (reg 0x44)
//---------------------------------
#define ADS_PHS_N1 0b101
#define ADS_PHS_0  0b000
#define ADS_PHS_P1 0b111
#define ADS_PHS_P2 0b110

#endif
