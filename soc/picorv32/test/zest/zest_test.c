#include <stdint.h>
#include "common.h"
#include "settings.h"
#include "zest.h"

int main(void){
  for (size_t ix=0; ix<8; ix++) {
    int16_t dval = read_zest_adc(ix);
    if (0) printf("ADC chan %ld hex : %#06x\n", (long int) ix, (uint16_t)dval);
  }
  return 0;
}
