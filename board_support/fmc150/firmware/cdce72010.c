#include <stdint.h>
#include "cdce72010.h"
#include "settings.h"
#include "spi.h"

void cdce72010_write_reg( uint8_t regAddr, uint32_t val ){
    CDCE72010_SS_SET(0);
    SPI_SET_DAT_BLOCK( (BASE_FMC150_SPI), ((val)<<4)|((regAddr)&0x0F) );
    CDCE72010_SS_SET(1);
}

uint32_t cdce72010_read_reg( uint8_t regAddr ) {
    cdce72010_write_reg( 0x0E, regAddr );
    CDCE72010_SS_SET(0);
    SPI_SET_DAT_BLOCK( BASE_FMC150_SPI, 0 );
    CDCE72010_SS_SET(1);
    return SPI_GET_DAT( BASE_FMC150_SPI )>>4;
}
