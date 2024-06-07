#include <stdint.h>
#include "common.h"
#include "settings.h"
#include "zest.h"

int main(void){
  int16_t dval;
  size_t ix;
  for (ix=0; ix<8; ix++) {
    dval = read_zest_adc(ix);
    // printf("ADC chan %d hex : %#06x\n", ix, (uint16_t)dval);
  }
  return 0;
}
