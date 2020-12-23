#include <stdint.h>
#include "dac3283.h"
#include "settings.h"
#include "spi.h"
#include "timer.h"
#include "print.h"
#include "fmc150.h"

// 5 bit regAddr,  8 bit val
void dac3283_write_reg( uint8_t regAddr, uint8_t val )
{
    DAC3283_SS_SET(0);
    // Transfer instruction byte
    SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, regAddr&0x1F );
    // Transfer data
    SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, val );
    DAC3283_SS_SET(1);
}

uint8_t dac3283_read_reg( uint8_t regAddr )
{
    DAC3283_SS_SET(0);
    // Transfer instruction byte
    SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, (1<<7)|(regAddr&0x1F) );
    // Transfer dummy data
    SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, 0 );
    DAC3283_SS_SET(1);
    return SPI_GET_DAT( BASE_FMC150_SPI );
}

// Reset and synchronize OSERDES PHY with DAC by pulsing FRAME
// Check if the chip receives the test-pattern from FPGA correctly
t_fmc150Error dac3283_check_tp( void )
{
    unsigned result, timeOut=0;
    print_str("dac3283_check_tp()        ");
    DAC3283_TESTP(1);   // PHY: start sending pattern
    DAC3283_OSD_RST();  // Reset MMCM and OSERDES
    while( !DAC3283_IS_MMCM_LOCKED() ){
        DELAY_US(10);   // Wait for MMCM to stabilize (~13 us)
        if( timeOut++ > 32 ) return RET_ERR_DAC_UNLOCKED;
    }
    DAC3283_SPI_INIT();
    // DAC: enable pattern checker
    unsigned regBackup = dac3283_read_reg(0x01);
    dac3283_write_reg(0x01, regBackup|(1<<BIT_DAC_IOTEST_ENA));
    // Sync PHY and pattern checker with frame pulse
    // Note: important to do this _AFTER_ enabling the pattern checker
    DAC3283_OSD_FRM();
    // DAC: Clear alarms / error flags
    dac3283_write_reg(REG_DAC_IOTEST_RES,  0);
    dac3283_write_reg(REG_DAC_ALARM_FLAGS, 0);
    dac3283_reset_al();
    // DAC: pattern check ...
    DELAY_MS(200);
    result = dac3283_read_reg(REG_DAC_IOTEST_RES);
    // Disable IO test mode
    dac3283_write_reg(0x01, regBackup);
    DAC3283_TESTP(0);
    if(result!=0){
        _putchar(' ');
        print_hex( result, 2 );
        _putchar(' ');
        return RET_ERR_DAC_TP;
    }
    return RET_OK;
}

// Check for alarm flags (clk alarm, fifo alarm)
t_fmc150Error dac3283_check_al( void )
{
    DAC3283_SPI_INIT();
    uint8_t val = dac3283_read_reg(REG_DAC_V31);
    if ( val & ((1<<BIT_DAC_CLK_ALARM)|(1<<BIT_DAC_TX_OFF)) ){
        return RET_ERR_DAC_CLK;
    }
//    val = dac3283_read_reg(REG_DAC_ALARM_FLAGS);
//    if( val ){
//        print_hex( val, 2 );
//        _putchar(' ');
//        return RET_ERR_DAC_FIFO;
//    }
    return RET_OK;
}

// clock alarm is latching and is reset here
void dac3283_reset_al( void )
{
    dac3283_write_reg(0x11, 0x24);
    dac3283_write_reg(0x11, 0x24|(1<<BIT_DAC_CLK_ALARM_ENA)|(1<<BIT_DAC_TX_OFF_ENA));
}
