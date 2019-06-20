#include <stdint.h>
#include <stdbool.h>
#include "settings.h"
#include "common.h"
#include "xadc.h"
#include "sfr.h"

int main(void) {
    bool busy = true;

    SET_REG(BASE_XADC + (0x48<<2), 0x100); // temp
    SET_REG(BASE_XADC + (0x49<<2), 0xff); // aux 0-7
    SET_SFR1(BASE_XADC + XADC_BASE2_SFR, 0, SFR_BIT_XADC_RESET, 1);
    // GET_REG(BASE_XADC + XADC_BASE2_SFR);
    GET_REG(BASE_XADC + (0x41<<2));
    GET_REG(BASE_XADC + (0x42<<2));
    GET_REG(BASE_XADC + (0x49<<2));
    while (busy) {
        busy = GET_SFR1(BASE_XADC + XADC_BASE2_SFR, 0, SFR_BIT_BUSY);
    }
    GET_REG(BASE_XADC + (XADC_CHAN_TEMP<<2));
    GET_REG(BASE_XADC + (XADC_CHAN_VAUX0<<2));
    GET_REG(BASE_XADC + (XADC_CHAN_VAUX3<<2));
    return 0;
}
