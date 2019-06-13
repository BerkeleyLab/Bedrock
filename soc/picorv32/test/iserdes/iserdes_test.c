#include <stdint.h>
#include <stdbool.h>
#include "sfr.h"
#include "settings.h"
#include "print.h"
#include "iserdes.h"

void _putchar( char c ){
	SET_REG8( BASE_DBG_SFR, c);
}

int main(void){
    // LTC2175-14
    // TEST PATTERN 0x3fc0 (SPI: 0x03 = 0xbf, 0x04=0xc0)
    // 16-bit, two lane mode: (0x3fc0<<2) = 0xff00
    // each lane pattern = 0xf0
    int n_bitslip[2];

    for (int lane=0; lane<2; lane++) {
		iserdes_set_lane(BASE_LVDS_PHY, lane);
        n_bitslip[lane] = iserdes_align_bits(BASE_LVDS_PHY, LTC2175_TEST_PAT);
    }
    return 0;
}
