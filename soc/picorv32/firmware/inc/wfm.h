#ifndef WFM_H
#define WFM_H

#include <stdint.h>
#include <stdbool.h>
#include "common.h"

#define WFM_CFG_ADDR          0x1000
#define WFM_CFG_BYTE_WFM_LEN  0
#define WFM_CFG_BYTE_CHAN_SEL 2
#define WFM_CFG_BYTE_TRIG     3

static inline void setup_waveform(uint32_t base, uint8_t len) {
    SET_REG16(base + WFM_CFG_ADDR + WFM_CFG_BYTE_WFM_LEN, len);
}

static inline void select_waveform_chan(uint32_t base, uint8_t ch) {
    SET_REG8(base + WFM_CFG_ADDR + WFM_CFG_BYTE_CHAN_SEL, ch);
}

static inline void trigger_waveform(uint32_t base) {
    SET_REG8(base + WFM_CFG_ADDR + WFM_CFG_BYTE_TRIG, 1);
    SET_REG8(base + WFM_CFG_ADDR + WFM_CFG_BYTE_TRIG, 0);
}

static inline uint16_t read_waveform_addr(uint32_t base, uint8_t addr) {
    return GET_REG(base + (addr<<2));
}

#endif
