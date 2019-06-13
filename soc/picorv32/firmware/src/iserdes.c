#include "iserdes.h"
#include <stdint.h>
#include "print.h"
#include "settings.h"

// Scan whole range, find edges, set center of the eye
// return align status
bool iserdes_center_idelay(uint32_t base, uint8_t pattern) {
    uint8_t cnt;
    uint8_t dout;
    bool valid[32];
    int n_valid = 0;
    int diff;
    uint8_t r_edge=0, f_edge=0;

    for (cnt=0; cnt<32; cnt++) {
        iserdes_set_idelay(base, cnt);
        dout = iserdes_get_dq(base);

#ifdef _DEBUG_PRINT_
		print_hex(dout, 2);
		print_str(" ");
#endif
        valid[cnt] = (dout == pattern);
        n_valid += valid[cnt];
        if (cnt > 0) {
            diff = valid[cnt] - valid[cnt-1];
            if (diff==1) r_edge=cnt;
            else if (diff==-1) f_edge=cnt;
        }
    }
#ifdef _DEBUG_PRINT_
    print_str("\n");
#endif

    if (n_valid < 10 || f_edge <= r_edge) {
        // invalid eye, needs bitslip
        iserdes_set_idelay(base, 0);
        return false;
    } else {
        uint8_t center = ((r_edge + f_edge)/2);
        iserdes_set_idelay(base, center);
        dout = iserdes_get_dq(base);
        return dout==pattern;
    }
}

// return n_bitslip or -1 for failure
int iserdes_align_bits(uint32_t base, uint8_t pattern) {
    bool aligned=false;

	iserdes_reset(base);
    for (int cnt=0; cnt<16; cnt++) {
        aligned = iserdes_center_idelay(base, pattern);
        if (!aligned)
            iserdes_bitslip(base);
        else
            return cnt;
    }
    return -1;
}
