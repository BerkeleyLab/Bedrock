#include "amc7823.h"
#include "settings.h"
#include <stdint.h>
#include "timer.h"
#include "spi.h"

void amc7823_read_regs( uint8_t page, uint8_t regAddr, uint16_t *buffer, uint8_t len ){
    if (len==0) return;
    page &= 0x03;
    regAddr &= 0x1F;
    uint16_t cmdWord = (1<<15) | (page<<12) | (regAddr<<6) | (regAddr+len-1);
    AMC7823_SS_SET(0);
    SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, cmdWord );
    for ( int i=0; i<len; i++ ){
        SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, 0 );
        *buffer++ = SPI_GET_DAT( BASE_FMC150_SPI );
    }
    AMC7823_SS_SET(1);
}

void amc7823_write_regs( uint8_t page, uint8_t regAddr, uint16_t *buffer, uint8_t len ){
    if (len==0) return;
    page &= 0x03;
    regAddr &= 0x1F;
    uint16_t cmdWord = (0<<15) | (page<<12) | (regAddr<<6) | (regAddr+len-1);
    AMC7823_SS_SET(0);
    SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, cmdWord );
    for ( int i=0; i<len; i++ ){
        SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, *buffer++ );
    }
    AMC7823_SS_SET(1);
}

uint16_t amc7823_read_reg( uint8_t page, uint8_t regAddr ){
    uint16_t val;
    amc7823_read_regs( page, regAddr, &val, 1 );
    return val;
}

void amc7823_write_reg( uint8_t page, uint8_t regAddr, uint16_t val ){
    amc7823_write_regs( page, regAddr, &val, 1 );
}
