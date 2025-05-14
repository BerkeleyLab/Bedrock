#ifndef _MARBLE_H_
#define _MARBLE_H_
#include <stdint.h>
#include <stdbool.h>

#define MARBLE_VAR_MARBLE_V1_2 0
#define MARBLE_VAR_MARBLE_V1_3 1
#define MARBLE_VAR_MARBLE_V1_4 2
#define MARBLE_VAR_UNKNOWN     3

typedef union _DataDword {
    uint32_t value;
    unsigned char bytes[4];
} DataDword;

typedef union _DataWord {
    uint16_t value;
    unsigned char bytes[2];
} DataWord;

typedef struct t_reg8 {
    uint8_t addr;
    uint8_t data;
} t_reg8;

typedef struct t_reg16 {
    uint16_t addr;
    uint16_t data;
} t_reg16;

typedef struct {
    unsigned int len;
    t_reg16 *regmap;
} marble_init_word_t;

typedef struct {
    unsigned int len;
    t_reg8 *regmap;
} marble_init_byte_t;

typedef struct marble_init_t {
    uint8_t marble_variant;
    marble_init_word_t ina219_fmc1_data;
    marble_init_word_t ina219_fmc2_data;
    marble_init_word_t ina219_12v_data;
    marble_init_byte_t pca9555_qsfp_data;   // u34
    marble_init_byte_t pca9555_misc_data;   // u39
    marble_init_byte_t adn4600_data;
    uint64_t si570_freq_hz;
    bool enable_evr_gtx;
    bool enable_poll_status;
} marble_init_t;

typedef struct ina219_info_t {
    const uint8_t i2c_mux_sel;
    const uint8_t i2c_addr;
    /** schematic refdes */
    const unsigned char refdes[4];
    /** function name */
    const unsigned char name[4];
    const uint16_t rshunt_mOhm;
    const uint16_t current_lsb_uA;
    int16_t vshunt_uV;
    uint16_t vbus_mV;
    uint16_t power_uW;
    int32_t curr_uA;
} ina219_info_t;

typedef struct pca9555_info_t {
    const uint8_t i2c_mux_sel;
    const uint8_t i2c_addr;
    /** schematic refdes */
    const unsigned char refdes[4];
    /** function name */
    const unsigned char name[4];
    uint8_t i0_val;
    uint8_t i1_val;
} pca9555_info_t;

typedef struct adn4600_info_t {
    const uint8_t i2c_mux_sel;
    const uint8_t i2c_addr;
    /** schematic refdes */
    const unsigned char refdes[6];
    uint8_t xpt_status[8];
} adn4600_info_t;

/**
 * @struct qsfp_status
 * @brief Structure holding the parameters for QSFP status SFF-8636
 */
typedef struct qsfp_info_t {
    bool module_present;
    /** I2C multiplexer channel */
    const uint8_t i2c_mux_sel;
    /** I2C device address */
    const uint8_t i2c_addr;
    /** Page Select Page 00, Byte 127*/
    uint8_t page_select;
    /** Latched Tx4-1 Rx3-1 LOS indicator, Page 00h Byte 3 */
    uint8_t chan_stat_los;
    /** Internally measured temperature, LSB 1/256 C. Page 00h Byte 22-23 */
    int16_t temperature;
    /** Internally measured voltage, LSB 0.1 mV. Page 00h Byte 26-27 */
    uint16_t voltage;
    /** Tx bias current, LSB 2 microA, Page 00h Byte 42-49 */
    uint16_t bias_current[4];
    /** Rx power, LSB 0.1 microW, Page 00h Byte 34-41 */
    uint16_t rx_power[4];
    /** Tx power, LSB 0.1 microW, Page 00h Byte 50-57 */
    uint16_t tx_power[4];
    /** Page 00h Byte 148-163 */
    unsigned char vendor_name[16];
    /** Page 00h Byte 168-183 */
    unsigned char part_num[16];
    /** Page 00h Byte 196-211 */
    unsigned char serial_num[16];
} qsfp_info_t;

/**
 * @struct si570
 * @brief Structure holding si570 info
 */
typedef struct si570_info_t {
    /** I2C multiplexer channel */
    const uint8_t i2c_mux_sel;
    /** I2C device address */
    uint8_t i2c_addr;
    unsigned char regs[6];
    /** f_xtal, fixed,  0.09 ppb */
    uint64_t f_xtal_hz;
    /** 38-bit fractional multiplier  */
    uint64_t rfreq;
    uint64_t f_reset_hz;
    uint64_t f_dco_hz;
    uint64_t f_out_hz;
    /** start address */
    uint8_t start_addr;
    uint8_t hs_div;
    uint8_t n1;
} si570_info_t;

/**
 * @struct marble_dev
 * @brief Structure holding marble board info
 */
typedef struct marble_dev_t {
    uint8_t variant;
    ina219_info_t ina219_12v;
    ina219_info_t ina219_fmc1;
    ina219_info_t ina219_fmc2;
    pca9555_info_t pca9555_qsfp;
    pca9555_info_t pca9555_misc;
    qsfp_info_t qsfp1;
    qsfp_info_t qsfp2;
    adn4600_info_t adn4600;
    si570_info_t si570;
} marble_dev_t;

// i2c device address (7bit)
#define I2C_ADR_PCA9548        0x70
#define I2C_ADR_FMC1           0x50  // M24C02, GA0=0, GA1=0
#define I2C_ADR_FMC2           0x52  // M24C02, GA0=1, GA1=0
#define I2C_ADR_INA219_12V     0x42  // I2C_SEL_APPL: U57
#define I2C_ADR_INA219_FMC2    0x41  // I2C_SEL_APPL: U32
#define I2C_ADR_INA219_FMC1    0x40  // I2C_SEL_APPL: U17
#define I2C_ADR_PCA9555_QSFP   0x22  // I2C_SEL_APPL: U34
#define I2C_ADR_PCA9555_MISC   0x21  // I2C_SEL_APPL: U39
#define I2C_ADR_SI570_NCB      0x77  // I2C_SEL_APPL: Y6, 570NCB000933DG, 7ppm stability
#define I2C_ADR_SI570_NBB      0x55  // I2C_SEL_APPL: Y6, 570NBB001808DG, 20ppm stability
#define I2C_ADR_ADN4600        0x48  // I2C_SEL_CLK:  U2
#define I2C_ADR_QSFP           0x50  // I2C_SEL_QSFP1 / I2C_SEL_QSFP2

// i2c multiplexer channels
#define I2C_SEL_FMC1     (1<<0)
#define I2C_SEL_FMC2     (1<<1)
#define I2C_SEL_CLK      (1<<2)
#define I2C_SEL_SDRAM    (1<<3)
#define I2C_SEL_QSFP1    (1<<4)
#define I2C_SEL_QSFP2    (1<<5)
#define I2C_SEL_APPL     (1<<6)

/**
 * @brief PCA9548: Set the channel mask register I2C multiplexer.
 * @param ch  -  channel to be selected, 0-7
 * @return true on success
 */
bool marble_i2c_mux_set(uint8_t ch);

/**
 * Scan I2C from 0-127
 */
void marble_i2c_scan(void);

/**
 * Poll QSFP status
 * @param qsfp_param qsfp status struct
 */
void get_qsfp_info(qsfp_info_t *qsfp_param);

/**
 * Poll INA219 status
 * @param info pointer to ina219_info_t struct
 */
bool get_ina219_info(ina219_info_t *info);

/**
 * Write INA219 registers
 * @param info pointer to ina219_info_t struct
 * @param p_data pointer to marble_init_word_t struct
 */
bool set_ina219_info(ina219_info_t *info, marble_init_word_t *p_data);

/**
 * Poll PCA9555 I0/I1 status
 * @param info pointer to pca9555_info_t struct
 */
bool get_pca9555_info(pca9555_info_t *info);

/**
 * Write PCA9555 registers
 * @param info pointer to pca9555_info_t struct
 * @param p_data pointer to marble_init_byte_t struct
 */
bool set_pca9555_info(pca9555_info_t *info, marble_init_byte_t *p_data);

/**
 * Poll ADN4600 cross bar mapping status
 * @param info pointer to adn4600_info_t struct
 */
bool get_adn4600_info(adn4600_info_t *info);

/**
 * Write ADN4600 registers
 * @param info pointer to adn4600_info_t struct
 * @param p_data pointer to marble_init_byte_t struct
 */
bool set_adn4600_info(adn4600_info_t *info, marble_init_byte_t *p_data);

/**
 * Poll SI570 status
 * @param info pointer to si570_info_t struct
 */
bool get_si570_info(si570_info_t *info);


/**
 * Reset SI570
 * @param info pointer to si570_info_t struct
 */
bool reset_si570(si570_info_t *info);

/**
 * Calculate SI570 registers from si570_info, and write
 * @param info pointer to si570_info_t struct
 * @param f1_hz new frequency in Hz
 */
bool calc_si570_regs(si570_info_t *info, uint64_t f1_hz);

/**
 * Write SI570 registers from si570_info
 * @param info pointer to si570_info_t struct
 * @param f1_hz new frequency in Hz
 */
bool set_si570_regs(si570_info_t *info, uint64_t f1_hz);

/**
 * Poll marble board device info including ina219, pca9555, qsfp
 * @param marble pointer to marble_dev_t structure
 */
bool get_marble_info(marble_dev_t *marble);

/**
 * Poll marble board device info in a staged manner to prevent
 * long polling delays.  This function should be called in a
 * main loop, and when marble_info_complete() returns true,
 * fresh data is available to print using print_marble_status().
 * The function marble_info_reset() is available to reset the
 * polling state machine if needed.
 */
bool get_marble_info_staged(marble_dev_t *marble);
bool marble_info_complete(void);
void marble_info_reset(void);

/**
 * Initialize Marble board by programming i2c devices
 * including pca9555 and clock settings;
 * Poll all device information into marble_dev;
 * @param init_data pointer to marble_init_t structure
 */
bool init_marble(marble_init_t *init_data);

/**
 * Print marble dev information after get_marble_info()
 */
void print_marble_status(void);
#endif
