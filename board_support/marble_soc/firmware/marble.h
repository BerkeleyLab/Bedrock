#ifndef _MARBLE_H_
#define _MARBLE_H_

#include "settings.h"
#include <stdio.h>
#include <stdbool.h>

typedef union _DataDword {
    uint32_t value;
    unsigned char bytes[4];
} DataDword;

typedef union _DataWord {
    uint16_t value;
    unsigned char bytes[2];
} DataWord;

typedef struct {
    uint8_t addr;
    uint8_t data;
} t_reg8;

typedef struct {
    uint16_t addr;
    uint16_t data;
} t_reg16;

typedef struct {
    uint16_t current_lsb_uA;
    uint16_t power_lsb_uW;
} t_ina219_conf;

typedef struct {
    int16_t vshunt_uV;
    uint16_t vbus_mV;
    uint16_t power_uW;
    int32_t curr_uA;
} t_ina219_data;

typedef struct {
    uint8_t p0_val;
    uint8_t p1_val;
} t_pca9555_data;

// I2C multiplexer
enum I2C_SELECT {
    I2C_SEL_FMC1 = (1<<0),
    I2C_SEL_FMC2 = (1<<1),
    I2C_SEL_SFP1 = (1<<2),
    I2C_SEL_SFP4 = (1<<3),
    I2C_SEL_SFP3 = (1<<4),
    I2C_SEL_SFP2 = (1<<5),
    I2C_SEL_APP  = (1<<6),
    I2C_SEL_HDMI = (1<<7)
};

// I2C Address
enum I2C_ADDR {
    I2C_ADR_PCA9548      =  0x70,
    I2C_ADR_FMC1         =  0x00,
    I2C_ADR_FMC2         =  0x00,
    I2C_ADR_SFP_1        =  0x50,  // SFP ID block (standardized)
    I2C_ADR_SFP_2        =  0x51,  // Finisar advanced diagnostic block
    I2C_ADR_INA219_12V   =  0x42,  // TI digital current sensor U43
    I2C_ADR_INA219_FMC2  =  0x41,  // TI digital current sensor U32
    I2C_ADR_INA219_FMC1  =  0x40,  // TI digital current sensor U17
    I2C_ADR_PCA9555_SFP  =  0x22,  // U34
    I2C_ADR_PCA9555_MISC =  0x21,  // U39
    I2C_ADR_SI570        =  0x55  // Y6: 570BBC000121DG, https://www.silabs.com/timing/lookup-customize
};

/***************************************************************************//**
 * @brief Marble init
 *
 * @return false if error.
*******************************************************************************/
bool init_marble(void);

/***************************************************************************//**
 * @brief PCA9548: Set the channel mask register I2C multiplexer.
 * @param ch  -  channel to be selected.
 * @return 1 on success
*******************************************************************************/
uint8_t i2c_mux_set(uint8_t ch);

/***************************************************************************//**
 * @brief INA219: Word Write to reg_address on selected chip through i2c.
 *
 * @param i2c_addr - i2c address.
 * @param reg_addr - reg address.
 * @param i2c_data - i2c data.
 * @return false if error.
*******************************************************************************/
bool i2c_write_word(uint8_t i2c_addr, uint8_t reg_addr,  uint16_t i2c_data);

/***************************************************************************//**
 * @brief INA219: Word Read from reg_address on selected chip through i2c.
 *
 * @param i2c_addr - i2c address.
 * @param reg_addr - reg address.
 * @param i2c_data - pointer to read word data.
 * @return false if error.
*******************************************************************************/
bool i2c_read_word(uint8_t i2c_addr, uint8_t reg_addr,  uint16_t *i2c_data);

/***************************************************************************//**
 * @brief report various readings from i2c.
*******************************************************************************/
void print_marble_status(void);

#endif
