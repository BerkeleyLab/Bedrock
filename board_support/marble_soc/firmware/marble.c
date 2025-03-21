#include <stdbool.h>
#include "i2c_soft.h"
#include "sfr.h"
#include "xadc.h"
#include "timer.h"
#include "localbus.h"
#include "settings.h"
#include "print.h"
#ifdef NONSTD_PRINTF
    #include "printf.h"
#else
    #include <stdio.h>
#endif
#include "marble.h"

marble_dev_t marble = {
    .variant = MARBLE_VAR_UNKNOWN,
    .pca9555_qsfp ={
        .i2c_mux_sel = I2C_SEL_APPL, .i2c_addr = I2C_ADR_PCA9555_QSFP, .refdes = "U34", .name="QSFP"},
    .pca9555_misc ={
        .i2c_mux_sel = I2C_SEL_APPL, .i2c_addr = I2C_ADR_PCA9555_MISC, .refdes = "U39", .name="MISC"},
    .ina219_12v = {
        .i2c_mux_sel = I2C_SEL_APPL, .i2c_addr = I2C_ADR_INA219_12V, .refdes = "U57", .name="12V",
        .rshunt_mOhm = 27, .current_lsb_uA = 100},
    .ina219_fmc1 = {
        .i2c_mux_sel = I2C_SEL_APPL, .i2c_addr = I2C_ADR_INA219_FMC1, .refdes = "U17", .name="FMC1",
        .rshunt_mOhm = 82, .current_lsb_uA = 10},
    .ina219_fmc2 = {
        .i2c_mux_sel = I2C_SEL_APPL, .i2c_addr = I2C_ADR_INA219_FMC2, .refdes = "U32", .name="FMC2",
        .rshunt_mOhm = 82, .current_lsb_uA = 10},
    .qsfp1 = {
        .module_present = false, .page_select = 0,
        .i2c_mux_sel=I2C_SEL_QSFP1, .i2c_addr=I2C_ADR_QSFP},
    .qsfp2 = {
        .module_present = false, .page_select = 0,
        .i2c_mux_sel = I2C_SEL_QSFP2, .i2c_addr = I2C_ADR_QSFP},
    .adn4600 = {
        .i2c_mux_sel = I2C_SEL_CLK, .i2c_addr = I2C_ADR_ADN4600, .refdes = "U2"},
    .si570 = {
        .f_reset_hz = 0, .rfreq = 0ULL,
        .i2c_mux_sel = I2C_SEL_APPL, .i2c_addr = I2C_ADR_SI570_NBB}
};

static bool marble_i2c_write(uint8_t i2c_addr, uint8_t reg_addr, const uint8_t *data, uint16_t len) {
    return i2c_write_regs(i2c_addr, reg_addr, (uint8_t *)data, len);
}

static bool marble_i2c_read(uint8_t i2c_addr, uint8_t reg_addr, uint8_t *data, uint16_t len) {
    return i2c_read_regs(i2c_addr, reg_addr, data, len);
}

bool marble_i2c_mux_set( uint8_t ch ) {
    return i2c_write_regs(I2C_ADR_PCA9548, ch, 0, 0);
}

static uint16_t reorder_bytes(uint16_t a) {
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

void get_qsfp_info(qsfp_info_t *qsfp_param) {
    unsigned short i=0;
    unsigned char buf[8];

    marble_i2c_mux_set(qsfp_param->i2c_mux_sel);
   /* Map upper memory page 00h to bytes 128-255*/
    marble_i2c_write(qsfp_param->i2c_addr, 127, &qsfp_param->page_select, 1);

    marble_i2c_read(qsfp_param->i2c_addr, 148, qsfp_param->vendor_name, 16);
    marble_i2c_read(qsfp_param->i2c_addr, 168, qsfp_param->part_num, 16);
    marble_i2c_read(qsfp_param->i2c_addr, 196, qsfp_param->serial_num, 16);

    marble_i2c_read(qsfp_param->i2c_addr, 3, &qsfp_param->chan_stat_los, 1);
    marble_i2c_read(qsfp_param->i2c_addr, 22, buf, 2);
    qsfp_param->temperature = (int16_t)(buf[0] << 8 | buf[1]) >> 8;  // C
    marble_i2c_read(qsfp_param->i2c_addr, 26, buf, 2);
    qsfp_param->voltage = (uint16_t)(buf[0] << 8 | buf[1]) / 10;  // mV
    marble_i2c_read(qsfp_param->i2c_addr, 42, buf, 8);
    for (i=0; i < 4; i++) {
        qsfp_param->bias_current[i] = (uint16_t)(buf[2*i] << 8 | buf[2*i+1]) * 2;  // microA
    }
    marble_i2c_read(qsfp_param->i2c_addr, 50, buf, 8);
    for (i=0; i < 4; i++) {
        qsfp_param->tx_power[i] = (uint16_t)(buf[2*i] << 8 | buf[2*i+1]) / 10; // microW
    }
    marble_i2c_read(qsfp_param->i2c_addr, 34, buf, 8);
    for (i=0; i < 4; i++) {
        qsfp_param->rx_power[i] = (uint16_t)(buf[2*i] << 8 | buf[2*i+1]) / 10; // microW
    }
}

bool get_ina219_info(ina219_info_t *info) {
    bool ret = true;
    uint16_t regs[5];
    ret &= marble_i2c_mux_set(info->i2c_mux_sel);

    for (size_t i=0; i<5; i++) {
        ret &= i2c_read_word(info->i2c_addr, i, regs+i);
    }

    info->vshunt_uV = (int16_t)regs[1] * 100;
    info->vbus_mV = (regs[2] >> 3) * 4;
    info->power_uW = regs[3] * info->current_lsb_uA * 20;  // eqn (3)
    info->curr_uA = (int16_t)regs[4] * info->current_lsb_uA;
    return ret;
}

bool get_pca9555_info(pca9555_info_t *info) {
    bool ret = true;
    ret &= marble_i2c_mux_set(info->i2c_mux_sel);

    ret &= marble_i2c_read(info->i2c_addr, 0, &(info->i0_val), 1);
    ret &= marble_i2c_read(info->i2c_addr, 1, &(info->i1_val), 1);
    return ret;
}

bool get_adn4600_info(adn4600_info_t *info) {
    bool ret = true;
    ret &= marble_i2c_mux_set(info->i2c_mux_sel);
    for (unsigned ix=0; ix<8; ix++) {
        ret &= marble_i2c_read(info->i2c_addr, 0x50+ix, &info->xpt_status[ix], 1);
    }
    return ret;
}

bool reset_si570(si570_info_t *info) {
    bool ret = true;
    uint8_t reg_135 = (1<<7);
    ret &= marble_i2c_mux_set(info->i2c_mux_sel);
    // reset si570 to read default registers, corresponding to f_reset_hz
    i2c_write_regs(info->i2c_addr, 135, &reg_135, 1);
    DELAY_MS(10);
    info->f_out_hz = info->f_reset_hz;

    // calculate f_xtal_hz
    ret &= get_si570_info(info);
    debug_printf(" %s: SI570 f_xtal:  %12lu kHz\n", __func__, marble.si570.f_xtal_hz / 1000);
    debug_printf(" %s: SI570 f_out :  %12lu kHz\n", __func__, marble.si570.f_out_hz / 1000);
    return ret;
}

bool get_si570_info(si570_info_t *info) {
    bool ret = true;
    unsigned char *regs = &info->regs[0];

    ret &= marble_i2c_mux_set(info->i2c_mux_sel);
    for (unsigned ix=0; ix<6; ix++) {
        ret &= marble_i2c_read(info->i2c_addr, info->start_addr+ix, regs+ix, 1);
    }
    info->hs_div = (regs[0] >> 5) + 4;
    info->n1 = (((regs[0] & 0x1f) << 2) | (regs[1] >> 6)) + 1;
    info->rfreq = ((uint64_t)(regs[1] & 0x3f) << 32)
                    + ((uint64_t)regs[2] << 24)
                    + ((uint64_t)regs[3] << 16)
                    + ((uint64_t)regs[4] << 8) + (uint64_t)regs[5];
    info->f_dco_hz = info->f_out_hz * info->hs_div * info->n1;
    info->f_xtal_hz = info->f_dco_hz * (1 << 28) / info->rfreq;
    return ret;
}

bool calc_si570_dividers(si570_info_t *info, uint64_t f1_hz) {
    uint8_t hs_divs[] = {11, 9, 7, 6, 5, 4};
    uint64_t fdco;
    uint8_t n1;
    for (uint8_t i=0; i<65; i++) {
        n1 = (i==0) ? 1 : i * 2;
        for (uint8_t j=0; j<6; j++) {
            fdco = f1_hz * n1 * hs_divs[j];
            if (fdco > 5670000000) break;
            if (fdco > 4850000000) {
                info->hs_div = hs_divs[j];
                info->n1 = n1;
                info->f_dco_hz = fdco;
                info->rfreq = fdco * (1 << 28) / info->f_xtal_hz;
                debug_printf(" %s: SI570 HSDIV:  %12u\n", __func__, marble.si570.hs_div);
                debug_printf(" %s: SI570 N1   :  %12u\n", __func__, marble.si570.n1);
                debug_printf(" %s: SI570 f_dco:  %12lu MHz\n", __func__, marble.si570.f_dco_hz / 1000000);
                debug_printf(" %s: SI570 rfreq:  %12u\n", __func__, marble.si570.rfreq);
                return true;
            }
        }
    }
    printf(" %s: Failed to find valid si570 dividers.\n", __func__);
    return false;
}

bool calc_si570_regs(si570_info_t *info, uint64_t f1_hz) {
    bool ret = true;
    unsigned char *regs = &info->regs[0];
    ret &= reset_si570(info);
    ret &= calc_si570_dividers(info, f1_hz);
    uint8_t n1 = info->n1 - 1;
    uint8_t hs_div = info->hs_div - 4;
    regs[0] = (hs_div << 5) | ((n1 & 0x7C) >> 2);       // reg 7: hs_div[2:0], n1[6:2]
    regs[1] = ((n1 & 3) << 6) | (info->rfreq >> 32);    // reg 8: n1[1:0] rfreq[37:32]
    regs[2] = (info->rfreq >> 24) & 0xff;               // reg 9: rfreq[31:24]
    regs[3] = (info->rfreq >> 16) & 0xff;               // reg 10: rfreq[23:16]
    regs[4] = (info->rfreq >> 8) & 0xff;                // reg 11: rfreq[15:8]
    regs[5] = info->rfreq & 0xff;                       // reg 12: rfreq[7:0]
    return ret;
}

bool set_si570_regs(si570_info_t *info, uint64_t f1_hz) {
    bool ret = true;
    unsigned char *regs = &info->regs[0];

    uint8_t reg_freeze_dco = (1<<4);
    uint8_t reg_unfreeze_dco = 0;
    uint8_t reg_newfreq = (1<<6);

    ret &= marble_i2c_mux_set(info->i2c_mux_sel);
    // freeze DCO
    ret &= i2c_write_regs(info->i2c_addr, 137, &reg_freeze_dco, 1);

    for (unsigned ix=0; ix<6; ix++) {
        ret &= marble_i2c_write(info->i2c_addr, info->start_addr+ix, regs+ix, 1);
    }
    // Unfreeze DCO
    ret &= i2c_write_regs(info->i2c_addr, 137, &reg_unfreeze_dco, 1);

    // Assert NewFreq bit
    ret &= i2c_write_regs(info->i2c_addr, 135, &reg_newfreq, 1);

    // The process of freezing and unfreezing the DCO will
    // cause the output clock to momentarily stop and start at
    // any arbitrary point during a clock cycle. This process
    // can take up to 10 ms.
    DELAY_MS(20);
    if (ret) info->f_out_hz = f1_hz;
    return ret;
}

bool set_ina219_info(ina219_info_t *info, marble_init_word_t *p_data) {
    bool ret = true;
    ret &= marble_i2c_mux_set(info->i2c_mux_sel);
    ret &= i2c_write_regmap_word(
            info->i2c_addr, p_data->regmap, p_data->len);
    return ret;
}

bool set_pca9555_info(pca9555_info_t *info, marble_init_byte_t *p_data) {
    bool ret = true;
    ret &= marble_i2c_mux_set(info->i2c_mux_sel);
    ret &= i2c_write_regmap_byte(
            info->i2c_addr, p_data->regmap, p_data->len);
    return ret;
}

bool set_adn4600_info(adn4600_info_t *info, marble_init_byte_t *p_data) {
    bool ret = true;
    ret &= marble_i2c_mux_set(info->i2c_mux_sel);
    ret &= i2c_write_regmap_byte(
        info->i2c_addr, p_data->regmap, p_data->len);
    return ret;
}

static int marble_update_stage = 0;

bool marble_info_complete(void) {
    if (marble_update_stage == 0) return true;
    return false;
}

void marble_info_reset(void) {
    marble_update_stage = 0;
    return;
}

bool get_marble_info(marble_dev_t *marble) {
    bool ret = true;

    switch (marble_update_stage) {
        case 0:
            ret &= get_adn4600_info(&marble->adn4600);
            ++marble_update_stage;
            break;
        case 1:
            ret &= get_ina219_info(&marble->ina219_12v);
            ++marble_update_stage;
            break;
        case 2:
            ret &= get_ina219_info(&marble->ina219_fmc1);
            ++marble_update_stage;
            break;
        case 3:
            ret &= get_ina219_info(&marble->ina219_fmc2);
            ++marble_update_stage;
            break;
        case 4:
            ret &= get_pca9555_info(&marble->pca9555_qsfp);
            ++marble_update_stage;
            break;
        case 5:
            ret &= get_pca9555_info(&marble->pca9555_misc);
            ++marble_update_stage;
            break;
        case 6:
            marble->qsfp1.module_present = (marble->pca9555_qsfp.i0_val & 0x20) == 0;
            if (marble->qsfp1.module_present) {
                get_qsfp_info(&marble->qsfp1);
            }
            ++marble_update_stage;
            break;
        case 7:
            marble->qsfp2.module_present = (marble->pca9555_qsfp.i1_val & 0x20) == 0;
            if (marble->qsfp2.module_present) {
                get_qsfp_info(&marble->qsfp2);
            }
            ++marble_update_stage;
            break;
        default:
            ret &= get_si570_info(&marble->si570);
            marble_update_stage = 0;
            break;
    }
    return ret;
}

void print_marble_status(void) {
    ina219_info_t ina219[3] = {marble.ina219_fmc1, marble.ina219_fmc2, marble.ina219_12v};
    pca9555_info_t pca9555[2] = {marble.pca9555_qsfp, marble.pca9555_misc};
    qsfp_info_t qsfp[2] = {marble.qsfp1, marble.qsfp2};

    switch (marble.variant) {
        case MARBLE_VAR_MARBLE_V1_4:
            printf(" %s: Marble Variant 1.4\n", __func__);
            break;
        case MARBLE_VAR_MARBLE_V1_3:
            printf(" %s: Marble Variant 1.3\n", __func__);
            break;
        case MARBLE_VAR_MARBLE_V1_2:
            printf(" %s: Marble Variant 1.2\n", __func__);
            break;
        case MARBLE_VAR_UNKNOWN:
        default:
            printf(" %s: Marble Variant Unknown\n", __func__);
            break;
    }

    for (unsigned ix=0; ix<8; ix++) {
        printf(" %s: ADN4600: IN%1u -> OUT%1u\n", __func__, marble.adn4600.xpt_status[ix], ix);
    }

    // si570 register dump
    for (unsigned ix=0; ix<6; ix++) {
        printf(" %s: SI570: addr = %1u, val = %#04x \n",
            __func__, marble.si570.start_addr+ix, marble.si570.regs[ix]);
    }
    printf(" %s: SI570 HSDIV :  %12u\n", __func__, marble.si570.hs_div);
    printf(" %s: SI570 N1    :  %12u\n", __func__, marble.si570.n1);
    printf(" %s: SI570 f_xtal:  %12lu kHz\n", __func__, marble.si570.f_xtal_hz / 1000);
    printf(" %s: SI570 f_out :  %12lu kHz\n", __func__, marble.si570.f_out_hz / 1000);

    for (unsigned i=0; i<3; i++) {
        printf(" %s: INA219 %.4s, %.4s:\n", __func__, ina219[i].refdes, ina219[i].name);
        printf(" %s: Vshunt     :  %12d mV\n",  __func__, ina219[i].vshunt_uV / 1000);
        printf(" %s: Power      :  %12d mW\n",  __func__, ina219[i].power_uW / 1000);
        printf(" %s: Vbus       :  %12d mV\n",  __func__, ina219[i].vbus_mV);
        printf(" %s: Current    :  %12ld mA\n", __func__, ina219[i].curr_uA / 1000);
    }
    for (unsigned i=0; i<2; i++) {
        printf(" %s: PCA9555 %.4s, %.4s:\n",  __func__, pca9555[i].refdes, pca9555[i].name);
        printf(" %s: I0         :      %#12X\n",__func__,  pca9555[i].i0_val);
        printf(" %s: I1         :      %#12X\n",__func__,  pca9555[i].i1_val);
    }
// MICRO SIGN  https://en.wikipedia.org/wiki/%CE%9C#Character_encodings
#define MICRO "\u00b5"
    for (unsigned i=0; i<2; i++) {
        if (qsfp[i].module_present) {
            printf(" %s: QSFP%1u Vendor  :   %.16s\n",  __func__, i+1, qsfp[i].vendor_name);
            printf(" %s: QSFP%1u Part    :   %.16s\n",  __func__, i+1, qsfp[i].part_num);
            printf(" %s: QSFP%1u Serial  :   %.16s\n",  __func__, i+1, qsfp[i].serial_num);
            printf(" %s: QSFP%1u TXRX_LOS:   %#8X\n",   __func__, i+1, qsfp[i].chan_stat_los);
            printf(" %s: QSFP%1u Temp    :   %8d C\n",  __func__, i+1, qsfp[i].temperature);
            printf(" %s: QSFP%1u Volt    :   %8u mV\n", __func__, i+1, qsfp[i].voltage);
            for (unsigned j=0; j < 4; j++) {
                printf(" %s: QSFP%1u TxBias %u:   %8u " MICRO "A\n", __func__,
                        i+1, j, qsfp[i].bias_current[j]);
                printf(" %s: QSFP%1u TxPwr  %u:   %8u " MICRO "W\n", __func__,
                        i+1, j, qsfp[i].tx_power[j]);
                printf(" %s: QSFP%1u RxPwr  %d:   %8u " MICRO "W\n", __func__,
                        i+1, j, qsfp[i].rx_power[j]);
            }
        }
    }
}

// Set Marble variants, by init data
static void set_marble_variant(marble_init_t *init_data) {
    int8_t mb4_pcb_rev;

    if (init_data->marble_variant == MARBLE_VAR_UNKNOWN) {
#ifdef LB_MARBLE_SPI_MBOX
// Optional MMC Mailbox support, when marble.variant is MARBLE_VAR_UNKNOWN:
//    Read `MB4_PCB_REV` from mmc_mailbox.v through localbus, if gateware supports.
// Refer to mailbox content at:
// https://gitlab.lbl.gov/hdl-libraries/marble_mmc/-/blob/master/doc/mailbox.md
        // MB4_PCB_REV is at page 4 (page size is 16), offset 8
        mb4_pcb_rev = read_lb_reg(LB_MARBLE_SPI_MBOX + 4*16 + 8);
        if ((mb4_pcb_rev >> 4) == 0x1) {
            marble.variant = mb4_pcb_rev & 0xf;
            printf(" %s: Found MMC Mailbox. mb4_pcb_rev = %x\n", __func__, mb4_pcb_rev);
        } else {
            printf(" %s: Invalid MMC Mailbox reading: mb4_pcb_rev = %x\n", __func__, mb4_pcb_rev);
        }
#endif
    } else { // known Marble variant
        marble.variant = init_data->marble_variant;
    }
}

// look up si570 for i2c address:
// https://tools.skyworksinc.com/TimingUtility/timing-part-number-search-results.aspx
// https://www.skyworksinc.com/-/media/SkyWorks/SL/documents/public/data-sheets/Si570-71.pdf
static void configure_si570_nbb_i2c(void) {
        // 570NBB001808DGR, 20ppm
        marble.si570.i2c_addr = I2C_ADR_SI570_NBB;
        marble.si570.start_addr = 7;
        marble.si570.f_reset_hz = 270000000ULL;
}

static void configure_si570_ncb_i2c(void) {
        // 570NCB000933DG, 7ppm
        marble.si570.i2c_addr = I2C_ADR_SI570_NCB;
        marble.si570.start_addr = 13;
        marble.si570.f_reset_hz = 125000000ULL;
}

static void configure_marble_variant(void) {
    switch (marble.variant) {
    case MARBLE_VAR_MARBLE_V1_4:
        configure_si570_nbb_i2c();
        break;

    case MARBLE_VAR_MARBLE_V1_3:
    case MARBLE_VAR_MARBLE_V1_2:
        configure_si570_ncb_i2c();
        break;

    // Auto-determine Marble variants,
    // to support a project with mixed hardware versions
    case MARBLE_VAR_UNKNOWN:
    default:
        // in case mmc mailbox is not available, test i2c address for si570
        // reset si570 to read f_xtal_hz
        configure_si570_nbb_i2c();
        if (get_si570_info(&marble.si570)) {
            printf(" %s: Found SI570 NBB (Marble 1.4)\n", __func__);
            marble.variant = MARBLE_VAR_MARBLE_V1_4;
            break;
        }

        configure_si570_ncb_i2c();
        if (get_si570_info(&marble.si570)) {
            printf(" %s: Found SI570 NCB (Marble 1.3).\n", __func__);
            marble.variant = MARBLE_VAR_MARBLE_V1_3;
            break;
        }
        printf(" %s: Failed to determine Marble variant).\n", __func__);
        break;
    }
}

bool init_marble(marble_init_t *init_data)
{
    bool p = true;
    bool pass = true;

    printf("--===========  Marble Init  =============--\n");

    set_marble_variant(init_data);
    configure_marble_variant();

    p = calc_si570_regs(&marble.si570, init_data->si570_freq_hz); pass &= p;
    p &= set_si570_regs(&marble.si570, init_data->si570_freq_hz); pass &= p;
    printf("==== SI570 init  ====   : %s.\n", p?"PASS":"FAIL");

    p = set_ina219_info(&marble.ina219_fmc1, &init_data->ina219_fmc1_data);  pass &= p;
    p &= set_ina219_info(&marble.ina219_fmc2, &init_data->ina219_fmc2_data); pass &= p;
    p &= set_ina219_info(&marble.ina219_12v, &init_data->ina219_12v_data);   pass &= p;
    printf("==== INA219 init  ====  : %s.\n", p?"PASS":"FAIL");

    p = set_pca9555_info(&marble.pca9555_qsfp, &init_data->pca9555_qsfp_data);  pass &= p;
    p &= set_pca9555_info(&marble.pca9555_misc, &init_data->pca9555_misc_data); pass &= p;
    printf("==== PCA9555 init ====  : %s.\n", p?"PASS":"FAIL");

    p = set_adn4600_info(&marble.adn4600, &init_data->adn4600_data); pass &= p;
    printf("==== ADN4600 init ====  : %s.\n", p?"PASS":"FAIL");

    pass &= get_marble_info(&marble);
    print_marble_status();
    return pass;
}
