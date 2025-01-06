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
#define ZEST_BASE2_AWG   0x230000

// SFR REG
#define SFR_OUT_REG0            0
#define SFR_OUT_BYTE_PH_SEL     0
#define SFR_OUT_BYTE_FCLK_SEL   1
#define SFR_OUT_BYTE_CSB_SEL    2
#define SFR_OUT_BIT_ADC_PDWN    24
#define SFR_OUT_BIT_DAC_RESET   25
#define SFR_OUT_BIT_ADC_SYNC    26
#define SFR_OUT_BIT_PWR_SYNC    27
#define SFR_OUT_BIT_PWR_ENB     28
#define SFR_OUT_BIT_BUFR_A_RST  29
#define SFR_OUT_BIT_BUFR_B_RST  30
#define SFR_OUT_BIT_DSPCLK_RST  31

#define SFR_OUT_REG1            1
#define SFR_OUT_BIT_DAC0_SRCSEL 0
#define SFR_OUT_BIT_DAC0_ENABLE 1
#define SFR_OUT_BIT_DAC1_SRCSEL 2
#define SFR_OUT_BIT_DAC1_ENABLE 3

#define SFR_IN_REG_PCNT         0
#define SFR_IN_REG_FCNT         1
#define SFR_IN_BIT_DSPCLK_LOCKED 16

#ifndef FCNT_WIDTH
    #define FCNT_WIDTH              16
#endif

#ifndef PH_DIFF_DW
    #define PH_DIFF_DW              13
#endif

typedef enum ZEST_DEV {
    ZEST_DEV_ILLEGAL   =  0xFF,
    ZEST_DEV_AD9653A   =  0x00,     // U2 ADC
    ZEST_DEV_AD9653B   =  0x01,     // U3 ADC
    ZEST_DEV_AD9781    =  0x02,     // U4 DAC
    ZEST_DEV_LMK01801  =  0x03,     // U1 Clk
    ZEST_DEV_AD7794    =  0x04,     // U18 SPI ADC (Thermistors)
    ZEST_DEV_AMC7823   =  0x05,     // U15 housekeeping
    ZEST_DEV_AD9653_BOTH =  0x06    // U2+U3 ADC, write only
} zest_dev_t;

typedef enum ZEST_FREQ_PHS_NAMES {
    ZEST_FREQ_ADC0_DIV = 0,
    ZEST_FREQ_ADC1_DIV = 1,
    ZEST_FREQ_DAC_DCO = 2,
    ZEST_FREQ_DSP_CLK = 3
} zest_freq_t;

typedef struct {
    uint32_t addr;
    uint32_t data;
} t_reg32;

typedef struct {
    size_t len;
    t_reg32 *regmap;
} zest_init_data_t;

typedef struct {
    zest_init_data_t lmk01801_data;
    zest_init_data_t ad9653_data;
    zest_init_data_t ad9781_data;
    zest_init_data_t ad7794_data;
    zest_init_data_t amc7823_data;
    uint32_t *fcnt_exp;      // expected ADC0_DIV, ADC1_DIV, DAC_DCO, DSP_CLK
    int8_t *phs_center;      // expected ADC0_DIV, ADC1_DIV, DAC_DCO
    uint8_t *ad9781_smp;     // expected AD9781_SMP values
    bool enable_poll_status;
} zest_init_t;

typedef struct {
    uint8_t dev;
    uint8_t addr_len;
    uint8_t data_len;
    uint16_t addr_mask;
    uint32_t data_mask;
} zest_devinfo_t;

typedef struct zest_status_t
{
    uint32_t zest_frequencies[4];   // ADC0, ADC1, DAC_DCO, DSP_CLK
    int16_t zest_phases[3];         // ADC0, ADC1, DAC_DCO
    uint16_t amc7823_adcs[9];
    uint32_t ad7794_adcs[6];
} zest_status_t;


/***************************************************************************//**
 * @brief SYNC both A&B banks by writing R5 when SYNC0_AUTO high
*******************************************************************************/
void sync_zest_clocks(void);

/***************************************************************************//**
 * @brief Check freq in valid range
 * @param ch - ZEST_FREQ_PHS_NAMES
 * @param fcnt_exp - expected fcnt
 * @return pass             - true if all validation passes
*******************************************************************************/
bool check_zest_freq(zest_freq_t ch, uint32_t fcnt_exp);

/***************************************************************************//**
 * @brief Read clk_to_fpga clk frequency
 * @param ch - ZEST_FREQ_PHS_NAMES
 * @return raw freq_count result (28bits)
*******************************************************************************/
uint32_t read_zest_fcnt(zest_freq_t ch);

/***************************************************************************//**
 * @brief Read clk_to_fpga clk phase with respect to dsp_clk
 * @param ch - ZEST_FREQ_PHS_NAMES
 * @return raw freq_count result (13bits)
*******************************************************************************/
int16_t read_clk_div_ph(zest_freq_t ch);

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
void init_zest_clocks(zest_init_data_t *p_data);

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
 * @brief Reset MMCM from fpga_clk to dsp_clk
*******************************************************************************/
void reset_zest_pll(void);

/***************************************************************************//**
 * @brief Check MMCM PLL locked status
*******************************************************************************/
bool check_zest_pll(void);

/***************************************************************************//**
 * @brief Configure SPI settings and remember current device.
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
*******************************************************************************/
void init_zest_spi(zest_dev_t dev);

/***************************************************************************//**
 * @brief Write one register to specified device
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
 * @param addr    - spi register address
 * @param val     - spi register value
*******************************************************************************/
void write_zest_reg(zest_dev_t dev, uint32_t addr, uint32_t val);

/***************************************************************************//**
 * @brief Read one register from specified device
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
 * @param addr    - spi register address
*******************************************************************************/
uint32_t read_zest_reg(zest_dev_t dev, uint32_t addr);

/***************************************************************************//**
 * @brief Write list of t_reg32 to specified device
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
 * @param regmap  - pointer to t_reg32 list
 * @param len     - length of array
*******************************************************************************/
void write_zest_regs(zest_dev_t dev, const t_reg32 *regmap, size_t len);

/***************************************************************************//**
 * @brief Validate reg values from readback of specified device
 *
 * @param dev     - device ID, eg. ZEST_DEV_AD9653A
 * @param p_data  - pointer to init data structure to be compared
 * @return valid  - true if identical
*******************************************************************************/
bool check_zest_regs(zest_dev_t dev, const zest_init_data_t *p_data);

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
bool init_zest(uint32_t base, zest_init_t *init_data);

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
bool check_div_clk_phase(uint8_t ch, int8_t center);

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
bool align_adc_clk_phase(uint8_t ch, int8_t center);

/***************************************************************************//**
 * @brief Execute ad9781 BIST test.
 * @return pass             - true if all validation passes
*******************************************************************************/
bool check_ad9781_bist(void);

/***************************************************************************//**
 * @brief Get zest status
*******************************************************************************/
void get_zest_status(zest_status_t *zest);

/***************************************************************************//**
 * @brief Print zest status
*******************************************************************************/
void print_zest_status(void);

/***************************************************************************//**
 * @brief Test function.
 * @param base              - base address
 * @return pass             - true if all validation passes
*******************************************************************************/
bool init_zest_dbg(uint32_t base);

#endif
