#ifndef MDIO_H
#define MDIO_H

#include <stdint.h>
#define MDIO_PRE         0xffffffff
#define MDIO_ST          0b01
#define MDIO_OP_R        0b10
#define MDIO_OP_W        0b01
#define MDIO_TA          0b10

void mdio_init(void);                // initialize GPIO pins

void mdio_write_reg( uint8_t phyAddr, uint8_t regAddr, uint16_t regVal);

uint16_t mdio_read_reg( uint8_t phyAddr, uint8_t regAddr);
#endif
