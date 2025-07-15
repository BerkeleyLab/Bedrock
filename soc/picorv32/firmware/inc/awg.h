#ifndef AWG_H
#define AWG_H

#include <stdint.h>
#include <stdbool.h>
#include "common.h"

#define AWG_CFG_ADDR          0x8000
#define AWG_CFG_BYTE_AWG_LEN  0
#define AWG_CFG_BYTE_TRIG     3

static inline void awg_setup(uint32_t base, uint8_t len) {
    SET_REG16(base + AWG_CFG_ADDR + AWG_CFG_BYTE_AWG_LEN, len);
}

static inline void awg_trigger(uint32_t base) {
    SET_REG8(base + AWG_CFG_ADDR + AWG_CFG_BYTE_TRIG, 1);
    SET_REG8(base + AWG_CFG_ADDR + AWG_CFG_BYTE_TRIG, 0);
}

static inline void awg_write_dma(uint32_t base, uint16_t *buffer, uint16_t len) {
    for (uint16_t ix=0; ix<len; ix++) {
        SET_REG(base + (ix<<2), *buffer++);
    }
}

#endif
