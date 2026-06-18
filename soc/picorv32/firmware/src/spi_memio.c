#include <stdint.h>
#include "spi_memio.h"

static uint8_t memio_rxtx8( uint32_t base_addr, uint8_t val ){
    uint8_t ret = 0;
    for (int i=0; i<=7; i++){
        uint8_t bitVal = (val&0x80) != 0;
        MEMIO_PIN_SET( base_addr, 0b0001, 0, 0, bitVal );
        MEMIO_PIN_SET( base_addr, 0b0001, 0, 1, bitVal );
        ret = (ret<<1) | ((MEMIO_PIN_GET(base_addr)>>1)&0x01);
        val <<= 1;
    }
    return ret;
}

void memio_rxtxN( uint32_t base_addr, uint8_t *buffer, int length ){
    uint8_t storedConfig = GET_REG8( base_addr+REG_MEMIO_CFG+3 );
    MEMIO_MODE( base_addr, 0 );
    MEMIO_PIN_SET( base_addr, 0b0001, 1, 0, 0b0000 );
    for (int i=0; i<length; i++){
        *buffer = memio_rxtx8( base_addr, *buffer );
        buffer++;
    }
    // Restore state of `en` bit
    SET_REG8( base_addr+REG_MEMIO_CFG+3, storedConfig );
}
