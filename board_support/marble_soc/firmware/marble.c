#include <stdio.h>
#include <stdbool.h>
#include "printf.h"
#include "print.h"
#include "i2c_soft.h"
#include "marble.h"
#include "sfr.h"
#include "xadc.h"
#include "settings.h"

t_ina219_conf ina219_conf;

uint8_t i2c_mux_set( uint8_t ch ){
    return i2c_write_regs( I2C_ADR_PCA9548, ch, 0, 0 );
}

static uint16_t reorder_bytes(uint16_t a)
{
	uint16_t ret = ((a >> 8) & 0xff) | ((a & 0xff) << 8);
	return ret;
}

bool i2c_write_word(uint8_t i2c_addr, uint8_t reg_addr, uint16_t reg) {
    bool ret = true;
    DataWord data;
    data.value = reorder_bytes(reg);

    ret &= i2c_write_regs(i2c_addr, reg_addr, &data.bytes[0], 2);
    return ret;
}

bool i2c_read_word(uint8_t i2c_addr, uint8_t reg_addr, uint16_t *reg) {
    bool ret = true;
    DataWord rdata;

    ret &= i2c_read_regs(i2c_addr, reg_addr, &rdata.bytes[0], 2);
    *reg = reorder_bytes(rdata.value);
    return ret;
}

bool i2c_write_regmap_byte(uint8_t i2c_addr, t_reg8 *regmap, size_t len) {
    bool ret = true;
    while ( len-- > 0 ){
        ret &= i2c_write_regs(i2c_addr, regmap->addr, &(regmap->data), 1);
        regmap++;
    }
    return ret;
}

bool i2c_write_regmap_word(uint8_t i2c_addr, t_reg16 *regmap, size_t len) {
    bool ret = true;
    while ( len-- > 0 ){
        ret &= i2c_write_word(i2c_addr, regmap->addr, regmap->data);
        regmap++;
    }
    return ret;
}

bool init_i2c_app_devices(void) {
    bool ret = true;
    ret &= i2c_mux_set(I2C_SEL_APP);

    // ----------------------------- INA219 -----------------------------
    // VBUS_MAX = 12V
    // VSHUNT_MAX = 0.08    (PGA = /8, +-320mV @ config=0x399f)
    // RSHUNT = 0.082       ( 1/3 for I2C_ADR_INA219_12V )
    // 1. Determine max current
    //   MaxPossible_I = VSHUNT_MAX / RSHUNT = 0.96A
    // 2. Determine max expected current at 12V
    //   MaxExpected_I = 0.25A    (700mA @ VSS1P8V, 450mA @ VSS3P3V, 150mA @ VPP1P8V)
    // 3. Calculate possible range of LSBs (Min = 15-bit, Max = 12-bit)
    //   MinimumLSB = MaxExpected_I/32767 = 7.63e-6     (7.6uA per bit)
    //   MaximumLSB = MaxExpected_I/4096  = 61.0e-5      ( 61uA per bit)
    // 4. Choose an LSB between the min and max values
    //    (Preferrably a roundish number close to MinLSB)
    //   CurrentLSB = 1e-5 A (10uA per bit)
    // 5. Compute the calibration register
    //   Cal = trunc (0.04096 / (CurrentLSB * RSHUNT)) = 49950 (0xc31e)
    // 6. Calculate the power LSB
    //   PowerLSB = 20 * CurrentLSB = 2e-4 (200uW per bit)
    // 7. Compute the maximum current and shunt voltage values before overflow
    //   Max_Current = CurrentLSB * 32767 = 0.32767 A before overflow
    //   Max_Current_Before_Overflow = min(Max_Current, MaxPossible_I)
    //   Max_ShuntVoltage = Max_Current_Before_Overflow * RSHUNT = 0.02687V
    //   Max_ShuntVoltage_Before_Overflow = min(Max_ShuntVoltage, VSHUNT_MAX)
    // 8. Compute the Maximum Power
    //   MaximumPower = Max_Current_Before_Overflow * VBUS_MAX = 0.328 * 12V = 3.9W
    t_reg16 ina219_regmap[] = {
        {0, 0x399f},
        {5, 0xc31e}  // cal
    };
    ret &= i2c_write_regmap_word(
            I2C_ADR_INA219_FMC1, ina219_regmap,
            sizeof(ina219_regmap) / sizeof(ina219_regmap[0]));
    ret &= i2c_write_regmap_word(
            I2C_ADR_INA219_FMC2, ina219_regmap,
            sizeof(ina219_regmap) / sizeof(ina219_regmap[0]));
    ina219_conf.current_lsb_uA = 10;
    ina219_conf.power_lsb_uW = 200;

    // XXX 0x42 address not present on hardware
    // ret &= i2c_write_regmap_word(
    //         I2C_ADR_INA219_12V, ina219_regmap,
    //         sizeof(ina219_regmap) / sizeof(ina219_regmap[0]));

    // ----------------------------- PCA9555 -----------------------------
    // U34
    // P0[7:0] = [[LOS, DEF0, TX_DIS, TX_FAULT] for SFP_4,1]
    // P1[7:0] = [[LOS, DEF0, TX_DIS, TX_FAULT] for SFP_2,3]
    t_reg8 pca9555_u34_regmap[] = {
        {2, 0x20},  //enable TX1
        {3, 0x22},  //disable TX
        {4, 0},
        {5, 0},
        {6, 0xdd},
        {7, 0xdd}
    };
    // U39
    // P0[7:4] = CFG_WP_B, THERM, FANFAIL, ALERT
    // P0[3:0] = EN_CON_JTAG, EN_USB_JTAG, NC, SI570_OE
    // P1[7:4] = SFP1_RS, SFP1_RS, SFP1_RS, SFP1_RS,
    // P1[3:0] = LD11, LD12, NC, NC
    t_reg8 pca9555_u39_regmap[] = {
        {2, 0xff},  // LED on
        {3, 0xff},
        {4, 0},
        {5, 0x0c},  // invert LD polarity
        {6, 0x7c},  // 0x70?
        {7, 0x03}
    };

    ret &= i2c_write_regmap_byte(
            I2C_ADR_PCA9555_SFP, pca9555_u34_regmap,
            sizeof(pca9555_u34_regmap) / sizeof(pca9555_u34_regmap[0]));
    ret &= i2c_write_regmap_byte(
            I2C_ADR_PCA9555_MISC, pca9555_u39_regmap,
            sizeof(pca9555_u39_regmap) / sizeof(pca9555_u39_regmap[0]));
    return ret;
}

bool get_ina219_data(uint8_t i2c_addr, t_ina219_data *data) {
    bool ret = true;
    uint16_t regs[4];

    for (size_t i=1; i<5; i++) {
        ret &= i2c_read_word(i2c_addr, i, regs+i-1);
    }
    data->vshunt_uV = (int16_t)regs[0] * 10;
    data->vbus_mV = (regs[1] >> 3) * 4;
    data->power_uW = regs[2] * ina219_conf.power_lsb_uW;
    data->curr_uA = (int16_t)regs[3] * ina219_conf.current_lsb_uA;
    return ret;
}

bool get_pca9555_data(uint8_t i2c_addr, t_pca9555_data *data) {
    bool ret = true;
    ret &= i2c_read_regs(i2c_addr, 0, &(data->p0_val), 1);
    ret &= i2c_read_regs(i2c_addr, 1, &(data->p1_val), 1);
    return ret;
}

void print_xadc_data(uint16_t *data, uint8_t *chans, size_t len) {
    uint16_t scale=1;
    const char * name = "Temp   ";
    const char * unit = " V";
    for (size_t i=0; i<len; i++) {
        print_str("XADC   ");
        switch (chans[i]) {
            case XADC_CHAN_TEMP:
                // temp = data[i] * 503.975 / 4096 - 273.15;
                scale = 504; // UG480 Equation 2-6, 503.975
                data[i] -= 2220; // K to C, 273.15 * 4096 / 503.975
                unit = "degC";
                break;
            case XADC_CHAN_VCCINT:
                name = "VCCINT ";
                scale = 3;  // UG480 Equation 2-7
                unit = " V";
                break;
            case XADC_CHAN_VCCAUX:
                name = "VCCAUX ";
                scale = 3;  // UG480 Equation 2-7
                unit = " V";
                break;
            case XADC_CHAN_VCCBRAM:
                name = "VCCBRAM";
                scale = 3;  // UG480 Equation 2-7
                unit = " V";
                break;
            default:
                printf("  XADC chan %d: %#x\n", i, data[i]);
        }
        printf("%8s:", name);
        print_dec_fix( data[i]*scale, 12, 2 );
        printf(" %s\n", unit);
    }
}

void get_xadc_data(void) {
    bool busy=true;
    uint8_t chans[] = { XADC_CHAN_TEMP, XADC_CHAN_VCCINT, XADC_CHAN_VCCAUX, XADC_CHAN_VCCBRAM };
    uint16_t data[4];
    size_t len = sizeof(chans)/sizeof(chans[0]);

    while (busy) {
        busy = GET_SFR1(BASE_XADC + XADC_BASE2_SFR, 0, SFR_BIT_BUSY);
    }
    for (size_t i=0; i < len; i++) {
        data[i] = (GET_REG(BASE_XADC + (chans[i]<<2))) >> 4;
    }
    print_xadc_data(data, chans, len);
}

void print_marble_status(void) {
    t_ina219_data ina219[2];
    get_ina219_data(I2C_ADR_INA219_FMC1, &ina219[0]);
    get_ina219_data(I2C_ADR_INA219_FMC2, &ina219[1]);

    t_pca9555_data pca9555[2];
    get_pca9555_data(I2C_ADR_PCA9555_SFP, &pca9555[0]);
    get_pca9555_data(I2C_ADR_PCA9555_MISC, &pca9555[1]);

    for (size_t i=0; i<2; i++) {
        printf("INA219 FMC%1d:\n", i+1);
        // printf("Vshunt:  %6d uV\n", ina219[i].vshunt_uV);
        // printf("power:   %6d mW\n", ina219[i].power_uW / 1000);
        printf("Vbus:    %6d mV\n", ina219[i].vbus_mV);
        printf("current: %6d mA\n", ina219[i].curr_uA / 1000);

        printf("PCA9555 %1d:\n", i+1);
        printf("P0:      %#09b\n", pca9555[i].p0_val);
        printf("P1:      %#09b\n", pca9555[i].p1_val);
    }
    get_xadc_data();
}

bool init_marble(void) {
    bool ret = true;
    ret &= init_i2c_app_devices();
    return ret;
}

