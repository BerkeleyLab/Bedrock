#ifndef LOCALBUS_H
#define LOCALBUS_H

#include <stdint.h>
#include <stdbool.h>
#include "common.h"
#include "settings.h"

/***************************************************************************//**
 * @brief Read lb reg, return 32bit signed value.
*******************************************************************************/
inline int32_t read_lb_reg(uint32_t addr) {
    return GET_REG(BASE_LOCALBUS + (addr<<2));
}

/***************************************************************************//**
 * @brief write lb reg.
*******************************************************************************/
inline void write_lb_reg(uint32_t addr, int32_t val) {
    SET_REG(BASE_LOCALBUS + (addr<<2), val);
}

#endif
