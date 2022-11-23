#ifndef ZEST_H
#define ZEST_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
// #include "print.h"

// BASE2_ADDR
#define ZEST_BASE2_ADC   0x000000
#define ZEST_BASE2_SFR   0x200000
#define ZEST_BASE2_SPI   0x210000
#define ZEST_BASE2_WFM   0x220000

// SFR REG
#define SFR_OUT_BYTE_PH_SEL     0
#define SFR_OUT_BYTE_FCLK_SEL   1
#define SFR_OUT_BYTE_CSB_SEL    2
#define SFR_OUT_BIT_ADC_PDWN    24
#define SFR_OUT_BIT_DAC_RESET   25
#define SFR_OUT_BIT_ADC_SYNC    26
#define SFR_OUT_BIT_PWR_SYNC    27
#define SFR_OUT_BIT_PWR_ENB     28
#define SFR_WST_BIT_BUFR_A_RST  29
#define SFR_WST_BIT_BUFR_B_RST  30
#define SFR_IN_BYTE_PCNT        0
#define SFR_IN_BYTE_FCNT        2

#ifndef FCNT_WIDTH
    #define FCNT_WIDTH              15
#endif

enum ZEST_DEV {
    ZEST_DEV_ILLEGAL   =  0xFF,
    ZEST_DEV_AD9653A   =  0x00,     // U2 ADC
    ZEST_DEV_AD9653B   =  0x01,     // U3 ADC
    ZEST_DEV_AD9781    =  0x02,     // U4 DAC
    ZEST_DEV_LMK01801  =  0x03,     // U1 Clk
    ZEST_DEV_AD7794    =  0x04,     // U18 SPI ADC (Thermistors)
    ZEST_DEV_AMC7823   =  0x05,     // U15 housekeeping
    ZEST_DEV_AD9653_BOTH =  0x06    // U2+U3 ADC, write only
};

typedef struct {
    uint32_t addr;
    uint32_t data;
} t_reg32;

typedef struct {
    size_t len;
    t_reg32 *regmap;
} t_init_data;

typedef struct {
    t_init_data lmk01801_data;
    t_init_data ad9653_data;
    t_init_data ad9781_data;
    t_init_data ad7794_data;
    t_init_data amc7823_data;
    uint16_t *fcnt_exp;       // expected DSP_CLK, ADC0_DIV, ADC1_DIV, DAC_DCO
    uint8_t *phs_center;      // expected ADC0_DIV, ADC1_DIV, DAC_DCO, AD9781_SMP
} t_zest_init;

typedef struct {
    uint8_t dev;
    uint8_t addr_len;
    uint8_t data_len;
    uint16_t addr_mask;
    uint32_t data_mask;
} t_devinfo;

/***************************************************************************//**
 * @brief SYNC both A&B banks by writing R5 when SYNC0_AUTO high
*******************************************************************************/
void sync_zest_clocks(void);

/***************************************************************************//**
 * @brief Check freq in valid range
 * @param ch - 0,1,2,3 for dsp_clk, clk_div0, clk_div1
 * @param fcnt_exp - expected fcnt
 * @return pass             - true if all validation passes
*******************************************************************************/
bool check_zest_freq(uint8_t ch, uint16_t fcnt_exp);

/***************************************************************************//**
 * @brief Read clk_to_fpga clk frequency
 * @param ch - 0,1,2,3 for dsp_clk, clk_div0, clk_div1
 * @return raw freq_count result (16bits)
*******************************************************************************/
uint16_t read_zest_fcnt(uint8_t ch);

/***************************************************************************//**
 * @brief Read raw ADC count for selected channel
 * @param   ch  0-7
 * @return raw adc count
*******************************************************************************/
uint16_t read_zest_adc(uint8_t ch);

/***************************************************************************//**
 * @brief Read adc data
 * @param ch      -  0-7
*******************************************************************************/
uint16_t read_zest_adc(uint8_t ch);

/***************************************************************************//**
 * @brief Soft-reset, Program LMK registers, and soft sync.
 * @param init_data     - init register data.
*******************************************************************************/
void init_zest_clocks(t_init_data *p_data);

/***************************************************************************//**
 * @brief Program all ADC registers, align IDELAY and ISERDES.
 * @param base              - base address
 * @param bitslip_want      - expected bitslip for every lane, -1 to ignore
*******************************************************************************/
bool init_zest_adcs(uint32_t base, int8_t bitslip_want);

/***************************************************************************//**
 * @brief Reset BUFR from clk_dco to clk_div for selected channel
 * @param ch      -  0,1,2[,3]
*******************************************************************************/
void reset_zest_bufr(uint8_t ch);

/***************************************************************************//**
 * @brief Configure SPI settings and remember current device.
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
*******************************************************************************/
void init_zest_spi(uint8_t dev);

/***************************************************************************//**
 * @brief Write one register to specified device
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
 * @param addr    - spi register address
 * @param val     - spi register value
*******************************************************************************/
void write_zest_reg(uint8_t dev, uint32_t addr, uint32_t val);

/***************************************************************************//**
 * @brief Read one register from specified device
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
 * @param addr    - spi register address
*******************************************************************************/
uint32_t read_zest_reg(uint8_t dev, uint32_t addr);

/***************************************************************************//**
 * @brief Write list of t_reg32 to specified device
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
 * @param regmap  - pointer to t_reg32 list
 * @param len     - length of array
*******************************************************************************/
void write_zest_regs(uint8_t dev, const t_reg32 *regmap, size_t len);

/***************************************************************************//**
 * @brief Validate reg values from readback of specified device
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
 * @param p_data  - pointer to init data structure to be compared
 * @return valid  - true if identical
*******************************************************************************/
bool check_zest_regs(uint8_t dev, const t_init_data *p_data);

/***************************************************************************//**
 * @brief Update all AD9517 registers (0x232=0b1)
*******************************************************************************/
void update_zest_ad9517(void);

/***************************************************************************//**
 * @brief Initialize all subdevices.
 * @param base              - base address
 * @param zest_init_data    - pointer to init register data.
 * @return pass             - true if all validation passes
*******************************************************************************/
bool init_zest(uint32_t base, t_zest_init *init_data);

/***************************************************************************//**
 * @brief set global addresses
 * @param base              - base address
*******************************************************************************/
void select_zest_addr(uint32_t base);

/***************************************************************************//**
 * @brief Read AMC7823 ADC and print
*******************************************************************************/
void read_amc7823_adcs(void);

/***************************************************************************//**
 * @brief read AD7794 adc data, single conversion
 * @param ch - 0-5: AIN1-6, 6: Temp
*******************************************************************************/
uint32_t read_ad7794_channel(uint8_t ch);

/***************************************************************************//**
 * @brief Read AD7794 ADC and print
*******************************************************************************/
void read_ad7794_adcs(void);

/***************************************************************************//**
 * @brief check dsp_clk and AD9653 div_clk phase diff
 * @param ch - 0, 1 for U2 or U3
 * @param center - expected phase center
 * @return       - true if valid phase found
*******************************************************************************/
bool check_div_clk_phase(uint8_t ch, uint8_t center);

/***************************************************************************//**
 * @brief Generate pseudorandom binary sequence 9 (PRBS9)
 *        in 16-bit parrallel reprensentaion.
 *        Start from 75*16 = 1200 step to save time.
 *        https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence
 * @param buf - pointer to result array
 * @param len - number of 16-bit elements to generate
*******************************************************************************/
void gen_prbs9(uint16_t *buf, size_t len);

/***************************************************************************//**
 * @brief check all 8 ADC waveforms using pseudorandom binary sequence 9
 * @return  - true if all measured waveforms are valid
*******************************************************************************/
bool check_adc_prbs9(void);

void test_adc_pn9(uint8_t len);

/***************************************************************************//**
 * @brief Align the phase of clk_div from iserdes against dsp_clk by
 *          iteratively reseting BUFR
 * @param ch     - 0, 1 for U2 or U3
 * @param center - expected phase center
 * @return       - true if valid phase found
*******************************************************************************/
bool align_adc_clk_phase(uint8_t ch, uint8_t center);

bool init_zest_dbg(uint32_t base);

/* #define debug_printf(...) \ */
/*    do { if (DEBUG_PRINT) printf(__VA_ARGS__); } while (0) */
#endif
