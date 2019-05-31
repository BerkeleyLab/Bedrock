//-------------------------------------------------------------
// 32 General purpose input / output pins
//-------------------------------------------------------------
// supports bit-wise addressing (changing / reading a pin in 1 cycle)

#ifndef GPIO_H
#define GPIO_H

#include "sfr.h"

// for the `reg` argument, put one of these
#define GPIO_OUT_REG  0x00
#define GPIO_OE_REG   0x01
#define GPIO_IN_REG   0x02

//----------------------------
// writes / reads single bits
//----------------------------
// index = which bit to write, val = 1 or 0
#define SET_GPIO1(base_addr, reg, index, val) \
  SET_SFR1(base_addr, reg, index, val)

#define GET_GPIO1(base_addr, reg, index)      \
  GET_SFR1(base_addr, reg, index)

//----------------------------
// writes / reads bytes
//----------------------------
#define SET_GPIO8(base_addr, reg, index, val) \
  SET_REG8(base_addr+reg*4+index, val)

#define GET_GPIO8(base_addr, reg, index)      \
  GET_REG8(base_addr+reg*4+index)

//----------------------------
// writes / reads 16 bit words
//----------------------------
#define SET_GPIO16(base_addr, reg, index, val)\
  SET_REG16(base_addr+reg*4+index*2, val)

#define GET_GPIO16(base_addr, reg, index)     \
  GET_REG16(base_addr+reg*4+index*2)

//----------------------------
// writes / reads the full 32 bits
//----------------------------
#define SET_GPIO32(base_addr, reg, val)       \
  SET_REG(base_addr+(reg)*4, val)

#define GET_GPIO32(base_addr, reg)            \
  GET_REG(base_addr+(reg)*4)


#endif
