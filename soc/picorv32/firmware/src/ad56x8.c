#include "common.h"
#include "spi.h"
#include "ad56x8.h"
#include <stdint.h>

void AD5628_SetDac(uint8_t chan, uint16_t val) {
    AD56x8_SetReg(CMD_WRITEDAC, chan, (val << 8));
}

void AD5648_SetDac(uint8_t chan, uint16_t val) {
    AD56x8_SetReg(CMD_WRITEDAC, chan, (val << 6));
}

void AD5668_SetDac(uint8_t chan, uint16_t val) {
    AD56x8_SetReg(CMD_WRITEDAC, chan, (val << 4));
}

void AD56x8_SetReg(uint8_t cmd, uint8_t addr, uint32_t data) {
    uint32_t in_sr;
    in_sr = ((cmd & 0xf) << 24) | ((addr & 0xf) << 20) | (data & 0xfffff);
    SPI_SET_DAT_BLOCK(AD56X8_ADDR, in_sr);
}

void AD56x8_Init() {
    SPI_INIT(AD56X8_ADDR, 0, 0, 0, 1, 0, 32, 1);

    AD56x8_SetReg(CMD_RESET,  0xf, 0);
    AD56x8_SetReg(CMD_PWR_UPDN, 0, 0xff);
    AD56x8_SetReg(CMD_INT_REF,  0, 1);
    AD56x8_SetReg(CMD_LD_LDAC,  0, 0xff);
    AD56x8_SetReg(CMD_LD_CLR,   0, 0x3);
}
