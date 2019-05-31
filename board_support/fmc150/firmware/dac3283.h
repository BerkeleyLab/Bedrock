// DAC3283 Dual-Channel, 16-Bit, 800 MSPS,
// Digital-to-Analog Converter (DAC)
// Controlled over SPI, used on FMC150
// expects the following in settings.h
// #define BASE_FMC150_SPI 0x04000000

#ifndef DAC3283_H
#define DAC3283_H
#include "fmc150.h"
#include "settings.h"
#include "gpio.h"

// SFR module within dac3283.v
#define PIN_DAC3283_TRAINING        28
#define PIN_DAC3283_OSERDES_RST     29
#define PIN_DAC3283_FRAME           30

// Some DAC register definitions
#define REG_DAC_IOTEST_PAT        0x09  // This is dataword0 in the IO test pattern.
                                        // It is used with 7 other words to test the input data.
#define REG_DAC_IOTEST_RES        0x08  // The values of these bits tell which bit in the byte-wide LVDS bus
                                        // failed during the pattern checker test
#define REG_DAC_ALARM_FLAGS       0x07  // Global alarm flags (buffer over/underrun, pattern test)
#define REG_DAC_V31               0x1F

// Register 0x00
#define BIT_DAC_FIFO_ENA             6
#define BIT_DAC_FIFO_RESET_ENA       5
#define BIT_DAC_MULTI_SYNC_ENA       4
#define BIT_DAC_ALARM_OUT_ENA        3
#define BIT_DAC_ALARM_POL            2
// Register 0x01
#define BIT_DAC_TWOS                 0
#define BIT_DAC_IOTEST_ENA           2
// Register 0x07, REG_DAC_ALARM_FLAGS
#define BIT_DAC_ALARM_FROM_ZEROCHK   6
#define BIT_DAC_ALARM_FIFO_COLLISION 5
#define BIT_DAC_ALARM_FROM_IOTEST    3
#define BIT_DAC_ALARM_FIFO_2AWAY     1
#define BIT_DAC_ALARM_FIFO_1AWAY     0
// Register 0x11
#define BIT_DAC_CLK_ALARM_ENA        1 // When asserted the DATACLK monitor alarm is enabled
#define BIT_DAC_TX_OFF_ENA           0 // When asserted a clk_alarm event will automatically
                                       // disable the DAC outputs by setting them to midscale.
// Register 0x12
#define BIT_DAC_CLKDIV_SYNC_ENA      1
// Register 0x13
#define BIT_DAC_MULTI_SYNC_SEL       1 // FIFO sync source, 0=OSTR, 1=FRAME
#define BIT_DAC_BEQUALSA             7 // 1: DATA_A --> DAC_B
#define BIT_DAC_AEQUALSB             6 // 1: DATA_B --> DAC_A
// Register 0x1F, REG_DAC_V31
#define BIT_DAC_CLK_ALARM            7 // This bit is set to '1' when DATACLK is stopped for 4 clock
                                       // cycles. Once set, the bit needs to be cleared by writing a '0'.
#define BIT_DAC_TX_OFF               6 // This bit is set to '1' when the clk_alarm is triggered. When set
                                       // the DAC outputs are forced to mid-level. Once set, the bit needs
                                       // to be cleared by writing a '0'
// Register 0x17
#define BIT_DAC_SIF4_ENA             2 // When asserted the SIF interface becomes a 4 pin interface. The
                                       // ALARM pin is turned into a dedicated output for the reading of data.

// Must be called before each READ / WRITE
// Deal with 8 bit byte transfers
#define DAC3283_SPI_INIT() \
    SPI_INIT( (BASE_FMC150_SPI), 0, 0, 0, 0, 0, 8, 32 )

#define DAC3283_SS_SET(val) \
    SET_SFR1(BASE_FMC150_SFR, 0, PIN_DAC3283_NSS, val)

// val=0: force analog DAC output to 0 V
#define DAC3283_TXENABLE(val) \
    SET_GPIO1(BASE_FMC150_SFR, GPIO_OUT_REG, PIN_DAC3283_TXEN, val)

// Trigger an OSERDES reset
#define DAC3283_OSD_RST() \
    SET_SFR1( BASE_FMC150_DAC, 0, PIN_DAC3283_OSERDES_RST, 1 );

// Trigger a 4xDAC_DCLK wide pulse on the DAC FRAME input
// to synchronize the serialized bits
// TODO perhaps its better to make this part of DAC3283_OSD_RST
#define DAC3283_OSD_FRM() \
    SET_SFR1( BASE_FMC150_DAC, 0, PIN_DAC3283_FRAME, 1 );

// val=1: enable sending the verilog defined test pattern to DAC
#define DAC3283_TESTP(val) \
    SET_SFR1( BASE_FMC150_DAC, 0, PIN_DAC3283_TRAINING, val );

// Get frequency of dac_clk_in (DATACLK) clock.
// To print in MHz: print_udec_fix( DAC3283_GET_DAC_CLK()*125, 24, 3 );
// Where the reference clock is at 125 MHz
#define DAC3283_GET_DAC_CLK() (GET_REG(BASE_FMC150_DAC)&0x0FFFFFFF)

#define DAC3283_IS_MMCM_LOCKED() ((GET_REG(BASE_FMC150_DAC)&(1<<31))!=0)

// 5 bit regAddr,  8 bit val
void dac3283_write_reg( uint8_t regAddr, uint8_t val );

// 5 bit regAddr, returns 8 bit val
uint8_t dac3283_read_reg( uint8_t regAddr );

// Check if the chip receives the correct test-pattern from FPGA
t_fmc150Error dac3283_check_tp( void );

// Check for alarm flags (clk alarm, fifo alarm)
t_fmc150Error dac3283_check_al( void );

// Reset latched clock alarm
void dac3283_reset_al( void );

#endif
