#ifndef ISERDES_H
#define ISERDES_H

#include <stdint.h>
#include <stdbool.h>
#include "sfr.h"

#define BYTE_LANE_MUX      0
#define BYTE_IDELAY_CNT    1
#define BYTE_ISERDES_DQ    2
#define BIT_ISERDES_RESET  16
#define BIT_BITSLIP        17

inline void iserdes_set_lane(uint32_t base, uint8_t chan) {
	SET_REG8(base + BYTE_LANE_MUX, chan);
}

inline uint8_t iserdes_get_idelay(uint32_t base) {
    return GET_REG8(base + BYTE_IDELAY_CNT);
}

inline uint8_t iserdes_get_dq(uint32_t base) {
    return GET_REG8(base + BYTE_ISERDES_DQ);
}

inline void iserdes_set_idelay(uint32_t base, uint8_t cnt) {
    SET_REG8(base + BYTE_IDELAY_CNT, cnt);
}

inline void iserdes_reset(uint32_t base) {
    SET_SFR1(base, 0, BIT_ISERDES_RESET, 1);
}

inline void iserdes_bitslip(uint32_t base) {
    SET_SFR1(base, 0, BIT_BITSLIP, 1);
}

bool iserdes_center_idelay(uint32_t base, uint8_t pattern);

int iserdes_align_bits(uint32_t base, uint8_t pattern);

#endif
