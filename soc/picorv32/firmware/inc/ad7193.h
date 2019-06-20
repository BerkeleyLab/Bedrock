#ifndef _AD7193_H_
#define _AD7193_H_

#include <stdbool.h>
#include "settings.h"
#define AD7193_ADDR BASE_SPI1

// Table 16
#define AD7193_REG_COMM     0x00
#define AD7193_REG_STATUS   0x00
#define AD7193_REG_MODE     0x01
#define AD7193_REG_CONF     0x02
#define AD7193_REG_DATA     0x03
#define AD7193_REG_ID       0x04
#define AD7193_REG_GPOCON   0x05
#define AD7193_REG_OFFSET   0x06
#define AD7193_REG_FSCALE   0x07

#define AD7193_MODE_CONTINOUS 0x0
#define AD7193_MODE_SINGLE    0x1
#define AD7193_MODE_IDLE      0x2
#define AD7193_MODE_PDOWN     0x3
#define AD7193_MODE_INT_ZCAL  0x4
#define AD7193_MODE_INT_FCAL  0x5
#define AD7193_MODE_SYS_ZCAL  0x6
#define AD7193_MODE_SYS_FCAL  0x7

/* ID Register Bit Designations (AD7193_REG_ID) */
#define ID_AD7193               0x2
#define AD7193_ID_MASK          0x0F

/* Continous convert,
 * DAT_STA enabled,
 * Internal 4.92MHz clock,
 * SINC3,
 * disable filter/chop */
#define AD7193_MODE_DEFAULT 0x188001

/* REFIN1,
 * Peudo mode,
 * Bufferred,
 * AD0-AD7,
 * Bipolar,
 * Gain =1, ADC range +-2.5V */
#define AD7193_CONF_DEFAULT 0x04ff50

/***************************************************************************//**
 * @brief Checks if the AD7139 part is present by query on ID.
 *
 * @return status - Indicates if the part is present or not.
 *                   Example: -1 - SPI peripheral was not initialized.
 *                             0 - SPI peripheral is initialized.
*******************************************************************************/
char AD7193_Init(void);

/***************************************************************************//**
 * @brief Waits for RDY_B pin to go low.
 *
 * @return number of loop cycles.
*******************************************************************************/
uint32_t AD7193_WaitReady(void);

/***************************************************************************//**
 * @brief Write 24 bits data to register.
 *
 * @param addr - Address of the register, 3 bits.
 * @param data - Data value to write, 24bits.
*******************************************************************************/
void AD7193_SetReg(uint8_t addr, uint32_t data);

/***************************************************************************//**
 * @brief Read data in continous read mode (Fig 27)
 *        Need to set 0x5c to communicateion register first.
 *        Need to set 0x58 to communicateion register to exit.
 *
 * @return 24bit data with 8 bit status register.
*******************************************************************************/
uint32_t AD7193_GetDataContinuous(void);
uint32_t * AD7193_GetDataContinuousArray(void);

/***************************************************************************//**
 * @brief Read data in continous conversion mode (Fig 26)
 *        Need to set 0x58 to communicateion register first.
 *
 * @return 24bit data with 8 bit status register.
*******************************************************************************/
uint32_t AD7193_GetData(void);

/***************************************************************************//**
 * @brief Read 8 bit register
 *
 * @return 8 bit register content.
*******************************************************************************/
uint32_t AD7193_GetReg8(uint8_t addr);

/***************************************************************************//**
 * @brief Read 24 bit register
 *
 * @return 24 bit register content.
*******************************************************************************/
uint32_t AD7193_GetReg24(uint8_t addr);

/***************************************************************************//**
 * @brief Check if RDY_B is low.
 *
 * @return true if RDY_B is low.
*******************************************************************************/
bool AD7193_GetReady(void);

void AD7193_PrintStatus(void);
#endif
