#ifndef _MARBLE_H_
#define _MARBLE_H_

#include "settings.h"
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

// I2C multiplexer for both marblemini and marble
#define I2C_SEL_FMC1   (1<<0)
#define I2C_SEL_FMC2   (1<<1)
#define I2C_SEL_APP    (1<<6)

// I2C multiplexer for marblemini via PCA9548
#define MARBLEMINI_I2C_SEL_SFP1   (1<<2)
#define MARBLEMINI_I2C_SEL_SFP4   (1<<3)
#define MARBLEMINI_I2C_SEL_SFP3   (1<<4)
#define MARBLEMINI_I2C_SEL_SFP2   (1<<5)
#define MARBLEMINI_I2C_SEL_HDMI   (1<<7)

// I2C multiplexer for marble via PCA9548
#define MARBLE_I2C_SEL_CLK    (1<<2)
#define MARBLE_I2C_SEL_SDRAM  (1<<3)
#define MARBLE_I2C_SEL_QSFP1  (1<<4)
#define MARBLE_I2C_SEL_QSFP2  (1<<5)

// I2C Address
#define I2C_ADR_PCA9548         0x70
#define I2C_ADR_FMC1            0x00
#define I2C_ADR_FMC2            0x00
#define I2C_ADR_SFP_1           0x50   // SFP ID block (standardized)
#define I2C_ADR_SFP_2           0x51   // Finisar advanced diagnostic block
#define I2C_ADR_INA219_12V      0x42   // I2C_SEL_APP: TI digital current sensor U43
#define I2C_ADR_INA219_FMC2     0x41   // I2C_SEL_APP: TI digital current sensor U32
#define I2C_ADR_INA219_FMC1     0x40   // I2C_SEL_APP: TI digital current sensor U17
#define I2C_ADR_PCA9555_SFP     0x22   // I2C_SEL_APP: U34
#define I2C_ADR_PCA9555_MISC    0x21   // I2C_SEL_APP: U39
#define I2C_ADR_SI570           0x55   // Y6: 570BBC000121DG, https://www.silabs.com/timing/lookup-customize
#define I2C_ADR_ADN4600         0x48

/***************************************************************************//**
 * @brief Marble init
 *
 * @return false if error.
*******************************************************************************/
bool init_marble(void);

/***************************************************************************//**
 * @brief MarbleMini init
 *
 * @return false if error.
*******************************************************************************/
bool init_marblemini(void);

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
