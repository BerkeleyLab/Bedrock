#include "print.h"
#include "settings.h"
#include "xadc_mon.h"
#include "common.h"
#include <stdbool.h>

static uint16_t XADCValues[N_CHAN];

uint16_t * XADC_ReadAll(void) {
    for (uint8_t ix=0; ix<N_CHAN; ix++) {
        XADCValues[ix] = (GET_REG(BASE_LB_XADC + (ix << 2))) >> 4;
    }
    return XADCValues;
}

void XADC_PrintMonitor(uint16_t *data) {
    uint16_t scale;
    uint8_t chan, nBit=12;
    const char * name = "Temp   ";
    const char * unit = " Volt";
    for (chan=0; chan<N_CHAN; chan++) {
        print_str("XADC   ");
        switch (chan) {
            case XADC_CHAN_TEMP:
                unit = "degC";
                scale = 504; // UG480 Equation 2-6, 503.975
                data[chan] -= 2220; // K to C, 273.15*4096/503.975
                break;
            case XADC_CHAN_VCCINT:
                name = "VCCINT ";
                scale = 3;  // UG480 Equation 2-7
                unit = " Volt";
                break;
            case XADC_CHAN_VCCAUX:
                name = "VCCAUX ";
                scale = 3;  // UG480 Equation 2-7
                unit = " Volt";
                break;
            case XADC_CHAN_VCCBRAM:
                name = "VCCBRAM";
                scale = 3;  // UG480 Equation 2-7
                unit = " Volt";
                break;
            default:
                name = "ADCXXX ";
                scale = 1;   // VPP = 1
                unit = " Volt";
        }
        print_str(name);
        print_str(":   ");
        print_dec_fix( data[chan]*scale, nBit, 2 );
        print_str(unit);
        _putchar('\n');
    }
}
