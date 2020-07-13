#include <stdint.h>
#include <stdbool.h>
#include "settings.h"
#include "common.h"
#include "wfm.h"
#include "sfr.h"

int main(void) {
    SET_REG16(BASE_WFM + WFM_BASE2_SFR + SFR_BYTE_WFM_LEN, 16);
//    SET_REG8(BASE_WFM + WFM_BASE2_SFR + SFR_BYTE_CHAN_SEL, 1);
    SET_SFR1(BASE_WFM + WFM_BASE2_SFR, 0, SFR_WST_BIT_TRIG, 1);
    for (uint8_t addr=0; addr<16; addr++) {
        GET_REG(BASE_WFM + WFM_BASE2_ADDR + (addr<<2));
    }
    return 0;
}
