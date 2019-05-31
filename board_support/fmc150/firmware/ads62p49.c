#include <stdint.h>
#include "ads62p49.h"
#include "settings.h"
#include "spi.h"

// 8 bit regAddr,  8 bit val
void ads62p49_write_reg( uint8_t regAddr, uint8_t val )
{
    ADS62P49_SS_SET(0);
    // Transfer data
    SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, regAddr<<8 | val );
    ADS62P49_SS_SET(1);
}

uint8_t ads62p49_read_reg( uint8_t regAddr )
{
    uint8_t temp;
    ads62p49_write_reg( 0x00,    0x01 );   // serial readout = 1
    ads62p49_write_reg( regAddr, 0x00 );   // dummy write & read
    temp = SPI_GET_DAT( BASE_FMC150_SPI );
    ads62p49_write_reg( 0x00,    0x00 );   // serial readout = 0
    return temp;
}
