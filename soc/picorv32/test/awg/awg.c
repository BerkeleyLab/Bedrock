#include <stdint.h>
#include <stdbool.h>
#include "settings.h"
#include "common.h"
#include "awg.h"

int main(void) {
    uint32_t config_addr = BASE_AWG + AWG_CFG_ADDR;
    SET_REG16(config_addr + AWG_CFG_BYTE_AWG_LEN, 5);
    uint16_t buf[] = {1,2,3,4,5};
    awg_write_dma(BASE_AWG, buf, sizeof(buf) / sizeof(uint16_t));

    for (uint8_t addr=0; addr<5; addr++) {
        GET_REG(BASE_AWG + (addr<<2));
    }
    awg_trigger(BASE_AWG);

    return 0;
}
