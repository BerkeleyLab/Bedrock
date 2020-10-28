#ifndef SPI_MEMIO_H
#define SPI_MEMIO_H
#include "common.h"

#define REG_MEMIO_CFG    0xFFFFFC
// refer to picosoc/README.md
#define BIT_MEMIO_EN     31   // MEMIO Enable (set to 0 to bit bang SPI commands)
#define BIT_MEMIO_DDR    22   // DDR Enable bit
#define BIT_MEMIO_QSPI   21   // QSPI Enable bit
#define BIT_MEMIO_CONT   20   // CRM Enable bit (continous transfers)
#define BIT_MEMIO_DUMMY  16   // Read latency (dummy) cycles [4 bits]
// bit bang mode for manually controlling pins
#define BIT_MEMIO_OE      8   // 1 = DO output drivers enabled [4 bits]
#define BIT_MEMIO_CSB     5   // state of chip select pin
#define BIT_MEMIO_CLK     4   // state of clock pin
#define BIT_MEMIO_DO      0   // read DI / write DO pins [4 bits]

//-------------------------------
// Low level macros
//-------------------------------
// set en = 1 to enable memory mapped mode
// set en = 0 for direct pin control (bit-bang)
#define MEMIO_MODE(base_addr, en) \
    SET_REG8((base_addr) + REG_MEMIO_CFG + 3, (en) ? (1 << (BIT_MEMIO_EN - 24)) : 0)

// Configure memory mapped mode (and reset hardware)
#define MEMIO_CFG(base_addr, ddr, qspi, cont, dummy) \
    SET_REG8(                            \
        (base_addr) + REG_MEMIO_CFG + 2, \
        ((ddr)  <<(BIT_MEMIO_DDR  -16))| \
        ((qspi) <<(BIT_MEMIO_QSPI -16))| \
        ((cont) <<(BIT_MEMIO_CONT -16))| \
        ((dummy)<<(BIT_MEMIO_DUMMY-16))  \
   )

// set SPI-flash pins directly,
// call MEMIO_MODE(0) before!
// `oe` and `dout` are each 4 bit wide
#define MEMIO_PIN_SET(base_addr, oe, csb, clk, dout) \
    SET_REG16(                                       \
        (base_addr)+REG_MEMIO_CFG,                   \
        ((oe) <<BIT_MEMIO_OE)  | ((csb) <<BIT_MEMIO_CSB) | \
        ((clk)<<BIT_MEMIO_CLK) | ((dout)<<BIT_MEMIO_DO)    \
   )

// Get status of the 4 IO lines
#define MEMIO_PIN_GET(base_addr) \
    (GET_REG8((base_addr)+REG_MEMIO_CFG) & 0x0F)

//-------------------------------
// bit-bang function
//-------------------------------
// uses basic SPI mode
// sends buffer on D0 and samples D1 into buffer
// Note: first byte in buffer shall be the command
void memio_rxtxN(uint32_t base_addr, uint8_t *buffer, int length);

#endif
