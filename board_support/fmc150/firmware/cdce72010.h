// Ten Output High Performance Clock Synchronizer,
// Jitter Cleaner, and Clock Distributor
// Controlled over SPI, used on FMC150
// See: http://www.ti.com/lit/ds/scas858c/scas858c.pdf

#ifndef CDCE72010_H
#define CDCE72010_H
#include "fmc150.h"
#include "settings.h"

// Must be called before each READ / WRITE
// Always deal with 32 bit words
#define CDCE72010_SPI_INIT() \
    SPI_INIT( BASE_FMC150_SPI, 0, 0, 0, 0, 1, 32, 32 )

// Set val to 1 to power up
// Careful, this thing gets hot !!!
#define CDCE72010_POWER_EN( val ) \
    SET_SFR1(BASE_FMC150_SFR, 0, PIN_CDCE72010_NPDWN, (val))

// Set val to 1 to power up CCPD-033 LVPECL oscillator (internal reference)
#define CDCE72010_REF_EN( val ) \
    SET_SFR1(BASE_FMC150_SFR, 0, PIN_FMC150_REF_EN, (val))

#define CDCE72010_SS_SET(val) \
    SET_SFR1(BASE_FMC150_SFR, 0, PIN_CDCE72010_NSS, val)

// 4 bit addr, 28 bit VAL
void cdce72010_write_reg( uint8_t regAddr, uint32_t val );

// returns 28 bit VAL
uint32_t cdce72010_read_reg( uint8_t regAddr );

//----------------------------------
// Out divider register definitions
//----------------------------------
// PHADJ        [7 bit] Coarse phase adjust select for Output Divider
// OUTDIVRSEL   [7 bit] Output Divider ratio select (See Table 8)
// ENDIV        [1 bit] Enable divider when set to 1
// PECLHISWING  [1 bit] High Output Voltage Swing in LVPECL/LVDS Mode if set to 1
// OUTBUFMODE   [6 bit] 0x1A=Disabled, 0x20=LVPECL, 0x3A=LVDS, 0b00xxxx=LVCMOS

// Helper macro to shift the bits to the right place
#define CDC_CFG( PHADJ, OUTDIVRSEL, ENDIV, PECLHISWING, OUTBUFMODE ) \
    ( (OUTBUFMODE<<22) | (PECLHISWING<<21) | (ENDIV<<20) | (OUTDIVRSEL<<13) | (PHADJ<<6) )

// Output buffer logic level (OUTBUFMODE)
#define CDC_OFF     0x1A
#define CDC_LVPECL  0x20
#define CDC_LVDS    0x3A
#define CDC_LVCMOS  0x02

// Output Dividers and Feedback Divide Settings (OUTDIVRSEL)
// See Table 8
#define CDC_D1    0b0100000
#define CDC_D2    0b1000000
#define CDC_D3    0b1000001
#define CDC_D4    0b1000010
#define CDC_D5    0b1000011
#define CDC_D4P   0b0000000
#define CDC_D6    0b0000001
#define CDC_D8    0b0000010
#define CDC_D10   0b0000011
#define CDC_D8P   0b0000100
#define CDC_D12   0b0000101
#define CDC_D16   0b0000110
#define CDC_D20   0b0000111
#define CDC_D12P  0b0001000
#define CDC_D18   0b0001001
#define CDC_D24   0b0001010
#define CDC_D30   0b0001011
#define CDC_D16P  0b0001100
#define CDC_D24P  0b0001101
#define CDC_D32   0b0001110
#define CDC_D40   0b0001111
#define CDC_D20P  0b0010000
#define CDC_D30P  0b0010001
#define CDC_D40P  0b0010010
#define CDC_D50   0b0010011
#define CDC_D24PP 0b0010100
#define CDC_D36   0b0010101
#define CDC_D48   0b0010110
#define CDC_D60   0b0010111
#define CDC_D28   0b0011000
#define CDC_D42   0b0011001
#define CDC_D56   0b0011010
#define CDC_D70   0b0011011
#define CDC_D32P  0b0011100
#define CDC_D48P  0b0011101
#define CDC_D64   0b0011110
#define CDC_D80   0b0011111

// Reg 0x0
#define CDC_VCXOSEL      4
#define CDC_REFSELCNTRL  5
// Reg 0x3
#define DIS_FDET_REF     0
#define DIS_FDET_FB      1
// Reg 0x8
#define CDC_IN_LVPECL    1
#define CDC_IN_LVDS      3
#define CDC_IN_LVCMOS    0
// Reg 0xB
#define CDC_FB_DIS       2
#define CDC_FB_MUX_SEL  20
#define CDC_OUT_MUX_SEL 21
// Reg 0xC
#define CDC_NSLEEP       7
#define CDC_NRESET_HOLD  8

#endif
