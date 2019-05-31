#ifndef FMC11X_H
#define FMC11X_H

#include <stddef.h>
#include <stdbool.h>
#include "print.h"

// BASE2_ADDR
#define FMC11X_BASE2_ADC   0x000000
#define FMC11X_BASE2_SFR   0x200000
#define FMC11X_BASE2_SPI   0x210000

// SFR REG
#define SFR_BIT_BUFR_RESET      16
#define SFR_BYTE_DAT_MUX        0    // byte address of dat_mux [3:0]
#define SFR_BYTE_BUFR_MUX       1    // byte address of bufr_mux [3:0]
#define SFR_BYTE_DAT_MON        0    // byte address of dat_mon readback
#define SFR_BIT_PRSNT_M2C_L     24   // bit address of presnt_m2c status
#define SFR_BIT_PG_M2C          25   // bit address of presnt_m2c status

#define LTC2175_TEST_PAT 0xf0

enum FMC11X_DEV {
    FMC11X_DEV_ILLEGAL   =  0xFF,
    FMC11X_DEV_CPLD      =  0x00,
    FMC11X_DEV_LTC2175A  =  0x80,
    FMC11X_DEV_LTC2175B  =  0x81,
    FMC11X_DEV_LTC2175C  =  0x82,
    FMC11X_DEV_LTC2175D  =  0x83,
    FMC11X_DEV_AD9517    =  0x84,
    FMC11X_DEV_LTC2656A  =  0x85,
    FMC11X_DEV_LTC2656B  =  0x86
};

typedef struct {
    uint16_t addr;
    uint16_t val;
} t_reg16;

typedef struct {
    size_t len;
    t_reg16 *regmap;
} t_init_data;

typedef struct {
    t_init_data ad9517_data;
    t_init_data ltc2175_data;
    t_init_data ltc2656a_data;
    t_init_data ltc2656b_data;
} t_fmc11x_init;

typedef struct {
    uint8_t dev;
    uint8_t addr_len;
    uint8_t data_len;
    uint16_t addr_mask;
    uint16_t read_mask;
    uint16_t data_mask;
} t_devinfo;

/***************************************************************************//**
 * @brief Read adc data
 * @param ch      -  0-11[12-15]
*******************************************************************************/
uint16_t read_fmc11x_adc(uint8_t ch);

/***************************************************************************//**
 * @brief Soft-reset, Program AD9517 registers, and soft sync.
 * @param init_data     - init register data.
*******************************************************************************/
bool init_fmc11x_clocks(t_init_data *p_data);

/***************************************************************************//**
 * @brief Program all ADC registers, align IDELAY and ISERDES.
 * @param base              - base address
 * @param n_adc             - 3 for fmc112, 4 for fmc116
 * @param bitslip_want      - expected bitslip for every lane, -1 to ignore
*******************************************************************************/
bool init_fmc11x_adcs(uint32_t base, size_t n_adc, int8_t bitslip_want);

/***************************************************************************//**
 * @brief Reset BUFR from clk_dco to clk_div for selected channel
 * @param ch      -  0,1,2[,3]
*******************************************************************************/
void reset_fmc11x_bufr(uint8_t ch);

/***************************************************************************//**
 * @brief Configure SPI settings and remember current device.
 *
 * @param dev     - device ID, eg. FMC11X_DEV_CPLD
*******************************************************************************/
void init_fmc11x_spi(uint8_t dev);

/***************************************************************************//**
 * @brief Write one register to specified device through fmc11x cpld
 *
 * @param dev     - device ID, eg. FMC11X_DEV_CPLD
 * @param addr    - spi register address
 * @param val     - spi register value
*******************************************************************************/
void write_fmc11x_reg(uint8_t dev, uint16_t addr, uint16_t val);

/***************************************************************************//**
 * @brief Read one register from specified device through fmc11x cpld
 *
 * @param dev     - device ID, eg. FMC11X_DEV_CPLD
 * @param addr    - spi register address
*******************************************************************************/
uint16_t read_fmc11x_reg(uint8_t dev, uint16_t addr);

/***************************************************************************//**
 * @brief Write list of t_reg16 to specified device through fmc11x cpld
 *
 * @param dev     - device ID, eg. FMC11X_DEV_CPLD
 * @param regmap  - pointer to t_reg16 list
 * @param len     - length of array
*******************************************************************************/
void write_fmc11x_regs(uint8_t dev, const t_reg16 *regmap, size_t len);

/***************************************************************************//**
 * @brief Validate reg values from readback of specified device through fmc11x cpld
 *
 * @param dev     - device ID, eg. FMC11X_DEV_CPLD
 * @param p_data  - pointer to init data structure to be compared
 * @return valid  - true if identical
*******************************************************************************/
bool check_fmc11x_regs(uint8_t dev, const t_init_data *p_data);

/***************************************************************************//**
 * @brief Soft Reset AD9517
*******************************************************************************/
void sync_fmc11x_ad9517(void);

/***************************************************************************//**
 * @brief Update all AD9517 registers (0x232=0b1)
*******************************************************************************/
void update_fmc11x_ad9517(void);

/***************************************************************************//**
 * @brief Initialize all fmc11x subdevices.
 * @param base              - base address
 * @param n_adc             - 3 for fmc112, 4 for fmc116
 * @param fmc11x_init_data  - pointer to init register data for fmc11x.
 * @return pass             - true if all validation passes
*******************************************************************************/
bool init_fmc11x(uint32_t base, size_t n_adc, t_fmc11x_init *init_data);

/***************************************************************************//**
 * @brief set global addresses
*******************************************************************************/
void select_fmc11x_addr(uint32_t base);

inline void print_reg(const char* str, uint16_t addr, uint16_t val) {
    print_str(str);
    print_str(": ( ");
    print_hex(addr, 4 );
    print_str(", ");
    print_hex(val,  4 );
    print_str(" )\n");
}
#endif
