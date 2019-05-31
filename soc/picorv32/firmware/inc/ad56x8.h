#ifndef AD56X8_H
#define AD56X8_H

#include <stdint.h>
#include "common.h"
#include "settings.h"

#define AD56X8_ADDR BASE_SPI0

// Table 9
#define CMD_WRITE       0b0000
#define CMD_UPDATEN     0b0001
#define CMD_UPDATEA     0b0010
#define CMD_WRITEDAC    0b0011
#define CMD_PWR_UPDN    0b0100
#define CMD_LD_CLR      0b0101
#define CMD_LD_LDAC     0b0110
#define CMD_RESET       0b0111
#define CMD_INT_REF     0b1000

// Set reference
void AD56x8_Init(void);

void AD56x8_SetReg(uint8_t cmd, uint8_t addr, uint32_t data);
void AD5628_SetDac(uint8_t chan, uint16_t val);
void AD5648_SetDac(uint8_t chan, uint16_t val);
void AD5668_SetDac(uint8_t chan, uint16_t val);
#endif
