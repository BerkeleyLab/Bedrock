// Special function register bit-wise access
// only works with instances of sfr_pack.v
#ifndef SFR_H
#define SFR_H
#include "common.h"

// Set / Clear a SFR bit
#define SET_SFR1(base_addr, reg, bit, val)                      \
  SET_REG(                                                      \
    (base_addr) | ((reg)<<9) | (((val)?1:2)<<7) | ((bit)<<2),   \
    0                                                           \
  )

// Return state of a SFR bit
#define GET_SFR1(base_addr, reg, bit)                           \
  GET_REG(                                                      \
    (base_addr) | ((reg)<<9) |           (1<<7) | ((bit)<<2)    \
  )

#endif
