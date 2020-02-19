#ifndef _FMC120_H_
#define _FMC120_H_

#include "settings.h"
#include <stdbool.h>

// FMC120 user manual Table 10
// #define I2C_ADR_FMC120_M24C02    0x50
// #define I2C_ADR_FMC120_AD7291    0x2F
// #define I2C_ADR_FMC120_CPLD      0x1C
// #define I2C_ADR_FMC120_LTC2657   0x10

typedef union _DataDword {
    uint32_t value;
    unsigned char bytes[4];
} DataDword;

typedef union _DataWord {
    uint16_t value;
    unsigned char bytes[2];
} DataWord;

typedef struct {
    uint16_t addr;
    uint16_t data;
} t_reg16;

typedef struct {
    uint32_t addr;
    uint32_t data;
} t_reg32;

enum CPLD_ADR {
    CPLD_ADR_COMMAND    =  0x00,
    CPLD_ADR_CONTROL0   =  0x01,
    CPLD_ADR_CONTROL1   =  0x02,
    CPLD_ADR_CONTROL2   =  0x03,
    CPLD_ADR_STATUS     =  0x04,
    CPLD_ADR_VERSION    =  0x05,
    CPLD_ADR_SPI_WDAT0  =  0x06,
    CPLD_ADR_SPI_WDAT1  =  0x07,
    CPLD_ADR_SPI_WDAT2  =  0x08,
    CPLD_ADR_SPI_RDAT0  =  0x0E,
    CPLD_ADR_SPI_RDAT1  =  0x0F
};

enum {
    FMC120_INTERNAL_CLK = 0,
    FMC120_EXTERNAL_CLK = 1
};

// CPLD COMMAND BITS
enum SPI_SELECT {
    LMK_SELECT = 0x1,
    DAC_SELECT = 0x2,
    ADC0_SELECT = 0x4,
    ADC1_SELECT = 0x8,
    ADC_SELECT_BOTH = 0xC
};

// CPLD CONTROL0 BITS
enum CONTROL0_ADR {
    OSC100_EN_ADR = 0x0,
    OSC500_EN_ADR = 0x1,
    ADC0_AMP_OFF_ADR = 0x2,
    ADC1_AMP_OFF_ADR = 0x3,
    LED_ON_ADR = 0x4
};

#define ADC_MODE_2CH_8LANE   0
#define ADC_MODE_4CH_8LANE   1
#define ADC_MODE_2CH_4LANE   2
#define ADC_MODE_4CH_4LANE   3

#define FMC120_DAC_PART_ID          0x0A   /*!< Expected part ID for this particular DAC chip */
#define FMC120_DAC_DLL_LOCKED       0x40   /*!< DAC chip's status register : DLL locked status */
#define FMC120_DAC_FIFO_ERROR       0x20   /*!< DAC chip's status register : FIFO check has failed */
#define FMC120_DAC_PATTERN_ERROR    0x10   /*!< DAC chip's status register : pattern check has failed */

/***************************************************************************//**
 * @brief Enable/disable DAC short test patten
 * @param enable        - active high
*******************************************************************************/
void FMC120_SetTestPatEnable(bool enable);

/***************************************************************************//**
 * @brief Checks if the FMC120 is present by query on ID. Setup monitors AD7291
 *
 * @param clockmode - FMC120_EXTERNAL_CLK, FMC120_INTERNAL_CLK.
 * @param ga        - Global Address {GA1,GA0} of AV57.1 FMC.
 * @param base_addr - BASE_ADDR of each fmc120.v inst
*******************************************************************************/
bool FMC120_Init(uint8_t clockmode, uint8_t ga, uint32_t base_addr);

/***************************************************************************//**
 * @brief Read AD7291 Temperature, and all 8 analog channels.
 *
 * @return 12bit data array.
*******************************************************************************/
uint32_t * FMC120_AD7291_ReadAll(void);

/***************************************************************************//**
 * @brief Print AD7291 Temperature, and all 8 analog channels.
 *
 * @param data - 9 channel raw data array returned by FMC120_AD7291_ReadAll
*******************************************************************************/
void FMC120_PrintMonitor(uint32_t *data);

/***************************************************************************//**
 * @brief Read CPLD ID.
 *
*******************************************************************************/
uint8_t FMC120_CPLD_GetVer(void);

/***************************************************************************//**
 * @brief SPI Write to selected chip through i2c.
 *
 * @param spi_select - enum SPI_SELECT, to CPLD CMD register.
 * @param spi_addr - spi address.
 * @param spi_data - spi data.
 * @return negative if error.
*******************************************************************************/
bool FMC120_SPI_Write(uint8_t spi_select, uint16_t spi_addr, uint16_t spi_data);

/***************************************************************************//**
 * @brief SPI Read to selected chip through i2c.
 *
 * @param spi_select - enum SPI_SELECT, to CPLD CMD register.
 * @param spi_addr - spi address.
 * @param spi_data - spi data.
 * @return negative if error.
*******************************************************************************/
bool FMC120_SPI_Read(uint8_t spi_select, uint16_t spi_addr, uint16_t *spi_data);

/***************************************************************************//**
 * @brief Init clock tree.
 *
 * @param clockmode - FMC120_EXTERNAL_CLK, FMC120_INTERNAL_CLK.
*******************************************************************************/
bool FMC120_InitClock(uint8_t clockmode);

/***************************************************************************//**
 * @brief Init DAC.
*******************************************************************************/
bool FMC120_InitDAC(void);

/***************************************************************************//**
 * @brief Init ADC.
*******************************************************************************/
bool FMC120_InitADC(void);

bool FMC120_ResetADC(void);

/***************************************************************************//**
 * @brief Reset ADC.
*******************************************************************************/
bool FMC120_ADS54J60_Reset(void);

/***************************************************************************//**
 * @brief DAC short pattern test.
 *
*******************************************************************************/
bool FMC120_ShortPatternTest(void);

/***************************************************************************//**
 * @brief Print FMC120 CTRL status. (fmc120_ctrl.vhd)
 *
*******************************************************************************/
void FMC120_PrintCtrlStatus(void);

/***************************************************************************//**
 * @brief Select i2c and axi address
 *
 * @param ga        - Global Address {GA1,GA0} of AV57.1 FMC.
 * @param base_addr - BASE_ADDR of each fmc120.v inst
*******************************************************************************/
void FMC120_SelectAddr(uint8_t ga, uint32_t base_addr);

/***************************************************************************//**
 * @brief Reset LMK04828
*******************************************************************************/
bool FMC120_LMK04828_Reset(void);

/***************************************************************************//**
 * @brief Set SYSREF_MUX=2, SYNC_MODE=2 for SYNC pin triggered pulse SYSREF
 *        datasheet section 9.3.2.1.1 step 2. (5)
*******************************************************************************/
bool FMC120_LMK04828_SetSYSREF(void);

/***************************************************************************//**
 * @brief Toggle LMK04828 SYNC pin
*******************************************************************************/
void FMC120_LMK04828_SyncAll(void);

/***************************************************************************//**
 * @brief Xilinx jesd204 core axi control interface:read
 * @param base_core        - Base2 address of jesd core (e.g. BASE_JESD_ADC0)
 * @param add              - Byte address of register. See PG066 Table 2-14
*******************************************************************************/
uint32_t read_jesd204_axi(uint32_t base_core, uint32_t add);

/***************************************************************************//**
 * @brief Xilinx jesd204 core axi control interface:write
 * @param base_core        - Base2 address of jesd core (e.g. BASE_JESD_ADC0)
 * @param add              - Byte address of register. See PG066 Table 2-14
*******************************************************************************/
void write_jesd204_axi(uint32_t base_core, uint32_t add, uint32_t val);

bool init_jesd204_core(void);

/***************************************************************************//**
 * @brief Xilinx jesd204 core soft reset
 * @param base_core        - Base2 address of jesd core (e.g. BASE_JESD_ADC0)
*******************************************************************************/
bool reset_jesd204_core(uint32_t base_core);

/***************************************************************************//**
 * @brief Xilinx jesd204 core check sync status by register 0x38
*******************************************************************************/
bool check_jesd204_sync(uint32_t base_core);

/***************************************************************************//**
 * @brief Print Xilinx jesd204_dac39j84 TX core registers
*******************************************************************************/
void FMC120_print_dac_core_status(void);

/***************************************************************************//**
 * @brief Print Xilinx jesd204_adc54j60 RX core registers
*******************************************************************************/
void FMC120_print_adc_core_status(void);

/***************************************************************************//**
 * @brief DAC39J84 check DAC PLL and lane/link alarms
 * @param pll_ena           - DAC PLL enable
*******************************************************************************/
bool FMC120_check_dac_alarms(bool pll_ena);

void FMC120_SetTxEnable(bool enable);
void FMC120_SetTestPatEnable(bool enable);

/***************************************************************************//**
 * @brief Check board presence by probing PRSNT_L pin
 * @return      - true if present
*******************************************************************************/
bool FMC120_CheckPrsnt(uint32_t base_addr);

#define FMC120_BASE2_SFR   0x100000

// BASE SFR
#define SFR_BIT_DAC_TX_EN           0
#define SFR_BIT_DAC_TP_EN           4

#define SFR_BIT_STAT_PG             16
#define SFR_BIT_STAT_PRSNT_L        17
#define SFR_BIT_STAT_ADC_A_OVER0    18
#define SFR_BIT_STAT_ADC_A_OVER1    19
#define SFR_BIT_STAT_ADC_B_OVER0    20
#define SFR_BIT_STAT_ADC_B_OVER1    21


// JESD SFR
#define FMC120_JESD_SFR             0x000000
#define BIT_STAT_TXTREADY           0
#define BIT_STAT_TXRESETN           1
#define BIT_STAT_RXRESETN_0         2
#define BIT_STAT_RXRESETN_1         3
#define BIT_STAT_RXRESET_DONE       4
#define BIT_STAT_TXRESET_DONE       5
#define BIT_STAT_QPLLLOCK_0         16
#define BIT_STAT_QPLLLOCK_1         17
#define BIT_STAT_RX_SYNC_0          18
#define BIT_STAT_RX_SYNC_1          19
#define BIT_STAT_TX_SYNC            20

#define BIT_TX_RESET                16
#define BIT_RX_RESET                17
#define BIT_TX_SYS_RESET            18
#define BIT_RX_SYS_RESET            19


#define BASE2_JESD_ADC0     0x010000
#define BASE2_JESD_ADC1     0x020000
#define BASE2_JESD_DAC      0x030000

#endif
