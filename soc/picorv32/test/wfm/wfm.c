#include <stdint.h>
#include <stdbool.h>
#include "settings.h"
#include "common.h"
#include "wfm.h"

int main(void) {
    uint32_t config_addr = BASE_WFM + WFM_CFG_ADDR;
    SET_REG16(config_addr + WFM_CFG_BYTE_WFM_LEN, 16);
    SET_REG8(config_addr + WFM_CFG_BYTE_CHAN_SEL, 1);
    SET_REG8(config_addr + WFM_CFG_BYTE_TRIG, 1);
    SET_REG8(config_addr + WFM_CFG_BYTE_TRIG, 0);
    for (uint8_t addr=0; addr<16; addr++) {
        GET_REG(BASE_WFM + (addr<<2));
    }
    return 0;
}
