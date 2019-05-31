#include <stdint.h>
#include <stdbool.h>
#include "fmc11x.h"
#include "settings.h"
#include "gpio.h"
#include "timer.h"
#include "spi.h"
#include "print.h"
#include "common.h"
#include "iserdes.h"
#include "sfr.h"

#ifdef _DEBUG_PRINT_
extern void print_reg(const char* str, uint16_t addr, uint16_t val);
#endif

uint32_t g_base_adc; //  = BASE_FMC11X + FMC11X_BASE2_ADC;
uint32_t g_base_sfr; //  = BASE_FMC11X + FMC11X_BASE2_SFR;
uint32_t g_base_spi; //  = BASE_FMC11X + FMC11X_BASE2_SPI;

static t_devinfo g_devinfo = {FMC11X_DEV_ILLEGAL, 0, 0, 0, 0, 0};

const uint8_t g_fmc11x_adcs[] = {
    FMC11X_DEV_LTC2175A,
    FMC11X_DEV_LTC2175B,
    FMC11X_DEV_LTC2175C,
    FMC11X_DEV_LTC2175D
};

uint16_t read_fmc11x_adc(uint8_t ch) {
    SET_REG8(g_base_sfr + SFR_BYTE_DAT_MUX, ch);
    return GET_REG16(g_base_sfr + SFR_BYTE_DAT_MON);
}

void init_fmc11x_spi(uint8_t dev) {
    uint8_t addr_len = 0;
    uint8_t data_len = 0;

    switch (dev) {
        case FMC11X_DEV_CPLD:
        case FMC11X_DEV_LTC2175A:
        case FMC11X_DEV_LTC2175B:
        case FMC11X_DEV_LTC2175C:
        case FMC11X_DEV_LTC2175D:
            addr_len = 8;
            data_len = 8;
            // SCK cycles = 16, CPOL=1, CPHA=1, DW=24, MSB first
            SPI_INIT(g_base_spi, 0, 0, 1, 1, 0, 24, 16);
            break;
        case FMC11X_DEV_AD9517  :
            addr_len = 16;
            data_len = 8;
            // SCK cycles = 16, CPOL=1, CPHA=1, DW=32, MSB first
            SPI_INIT(g_base_spi, 0, 0, 1, 1, 0, 32, 16);
            break;
        case FMC11X_DEV_LTC2656A:
        case FMC11X_DEV_LTC2656B:
            addr_len = 8;
            data_len = 16;
            // SCK cycles = 16, CPOL=1, CPHA=1, DW=32, MSB first
            SPI_INIT(g_base_spi, 0, 0, 1, 1, 0, 32, 16);
            break;
        default:
            g_devinfo.dev = FMC11X_DEV_ILLEGAL;
            return;
    }
    g_devinfo.dev = dev;
    g_devinfo.addr_len = addr_len;
    g_devinfo.data_len = data_len;
    g_devinfo.addr_mask = (1 << addr_len) - 1;
    g_devinfo.read_mask = 1 << (addr_len - 1);
    g_devinfo.data_mask = (1 << data_len) - 1;
}

void write_fmc11x_reg(uint8_t dev, uint16_t addr, uint16_t val) {
    uint32_t inst;

    if (dev != g_devinfo.dev) {
        init_fmc11x_spi(dev);
    }

    inst = (dev << (g_devinfo.addr_len + g_devinfo.data_len))
        + ((addr & g_devinfo.addr_mask) << g_devinfo.data_len) + val;

	SPI_SET_DAT_BLOCK( g_base_spi, inst );
}

uint16_t read_fmc11x_reg(uint8_t dev, uint16_t addr) {
    uint32_t inst;

    if (dev != g_devinfo.dev) {
        init_fmc11x_spi(dev);
    }

    inst = (dev << (g_devinfo.addr_len + g_devinfo.data_len))
           + (((addr & g_devinfo.addr_mask) | g_devinfo.read_mask) <<
                   g_devinfo.data_len);

	SPI_SET_DAT_BLOCK( g_base_spi, inst );
	return SPI_GET_DAT( g_base_spi ) & g_devinfo.data_mask;
}

void write_fmc11x_regs(uint8_t dev, const t_reg16 *regmap, size_t len) {
    while ( len-- > 0 ){
        write_fmc11x_reg(dev, regmap->addr, regmap->val);
        regmap++;
    }
}

bool check_fmc11x_regs(uint8_t dev, const t_init_data *p_data) {
    bool pass = true;
    uint16_t temp;
    size_t len = p_data->len;
    t_reg16 *regmap = p_data->regmap;

    while ( len-- > 0 ){
        temp = read_fmc11x_reg(dev, regmap->addr);
        pass &= regmap->val == temp;
#ifdef _DEBUG_PRINT_
        print_reg("SPI Check:", regmap->addr, temp);
#endif
        regmap++;
    }
    return pass;
}

void sync_fmc11x_ad9517(void) {
    t_reg16 regmap[] = {
        { 0x230, 0x01 }, // soft sync set
        { 0x232, 0x01 },
        { 0x230, 0x00 }, // soft sync reset
        { 0x232, 0x01 }
    };

    write_fmc11x_regs(FMC11X_DEV_AD9517, regmap, 4);
}

void update_fmc11x_ad9517(void) {
    write_fmc11x_reg(FMC11X_DEV_AD9517, 0x232, 0x01);
}

void reset_fmc11x_ad9517(void) {
    write_fmc11x_reg(FMC11X_DEV_AD9517, 0x0, 0x18|0x24);
    write_fmc11x_reg(FMC11X_DEV_AD9517, 0x0, 0x18);
}

bool init_fmc11x_clocks(t_init_data *p_data) {
    reset_fmc11x_ad9517();
    write_fmc11x_regs(FMC11X_DEV_AD9517, p_data->regmap, p_data->len);
    update_fmc11x_ad9517();
    sync_fmc11x_ad9517();
    DELAY_MS(100);

    return check_fmc11x_regs(FMC11X_DEV_AD9517, p_data);
}

void reset_fmc11x_bufr(uint8_t ch) {
    SET_REG8(g_base_sfr + SFR_BYTE_BUFR_MUX, ch);
    SET_SFR1(g_base_sfr, 0, SFR_BIT_BUFR_RESET, 1);
}

bool init_fmc11x_adcs(uint32_t base, size_t n_adc, int8_t bitslip_want) {
    bool pass = true;

    // Enable test pattern
    for (size_t ix=0; ix<n_adc; ix++) {
        write_fmc11x_reg(g_fmc11x_adcs[ix], 0x3, 0xbf);
    }

    // IDELAY scan and ISERDES bitslip alignment process
    int bitslips;
    uint8_t idelay;
    uint32_t ch_base;
    for (uint8_t chan=0; chan < n_adc*4; chan++) {

        ch_base = base + (chan << 16);
        print_str("  ADC ");
        print_dec(chan);
        print_str("\n");
        iserdes_reset(ch_base);

        for (uint8_t lane=0; lane<2; lane++) {
            iserdes_set_lane(ch_base, lane);
            bitslips = iserdes_align_bits(ch_base, LTC2175_TEST_PAT);
            idelay = iserdes_get_idelay(ch_base);
            print_str("    idelay = 0x");
            print_hex(idelay, 2);
            print_str(", bitslips = ");
            print_dec(bitslips);
            print_str("\n");

            if (bitslip_want >= 0) {
                pass &= bitslips == bitslip_want;
            } else {
                pass &= bitslips >= 0;
            }
        }
    }

    if (pass) {
        //------------------------------
        // Alignment done. Disable test pattern
        //------------------------------
        for (size_t ix=0; ix<n_adc; ix++) {
            write_fmc11x_reg(g_fmc11x_adcs[ix], 0x3, 0);
        }
    }

    return pass;
}

bool init_fmc11x_cpld(void) {
    uint16_t val;
    bool pass;
    write_fmc11x_reg(FMC11X_DEV_CPLD, 0, 0);     // External clock, External ref
    val = read_fmc11x_reg(FMC11X_DEV_CPLD, 0);
    pass = val==0;
    val = read_fmc11x_reg(FMC11X_DEV_CPLD, 2);
    pass &= (val & 0xf) == 0;                   // Ignore IRQ
    return pass;
}

void select_fmc11x_addr(uint32_t base) {
    g_base_adc = base + FMC11X_BASE2_ADC;
    g_base_sfr = base + FMC11X_BASE2_SFR;
    g_base_spi = base + FMC11X_BASE2_SPI;
}

bool init_fmc11x(uint32_t base, size_t n_adc, t_fmc11x_init *init_data) {
    bool pass=true;
    uint8_t byte;
    select_fmc11x_addr(base);

    byte = GET_SFR1(g_base_sfr, 0, SFR_BIT_PRSNT_M2C_L);
    // active low
    if (byte != 0) {
        print_str("FMC11X Not Present!\n");
        return false;
    }
    //------------------------------
    // CPLD init
    //------------------------------
    pass &= init_fmc11x_cpld();
    print_str("FMC11X CPLD  init : ");
    print_str(pass ? "PASS\n" : "FAIL\n");

    //------------------------------
    // AD9517 init
    //------------------------------
    t_init_data *p_ad9517_data = &(init_data->ad9517_data);
    t_init_data *p_ltc2175_data = &(init_data->ltc2175_data);
    t_init_data *p_ltc2656a_data = &(init_data->ltc2656a_data);
    t_init_data *p_ltc2656b_data = &(init_data->ltc2656b_data);

    pass &= init_fmc11x_clocks(p_ad9517_data);
    print_str("FMC11X Clock init : ");
    print_str(pass ? "PASS\n" : "FAIL\n");

    //------------------------------
    // LTC2175 init, after clock aligned.
    //------------------------------
    // pass &= init_fmc11x_adcs(n_adc);
    // print_str("FMC11X ADC init : ");
    // print_str(pass ? "PASS\n" : "FAIL\n");

    for (size_t ix=0; ix<n_adc; ix++) {
        write_fmc11x_regs(g_fmc11x_adcs[ix], p_ltc2175_data->regmap, p_ltc2175_data->len);
        pass &= check_fmc11x_regs(g_fmc11x_adcs[ix], p_ltc2175_data);
    }
    //------------------------------
    // LTC2656 init, SDO not available to readback
    //------------------------------
    write_fmc11x_regs(FMC11X_DEV_LTC2656A, p_ltc2656a_data->regmap, p_ltc2656a_data->len);
    write_fmc11x_regs(FMC11X_DEV_LTC2656B, p_ltc2656b_data->regmap, p_ltc2656b_data->len);

    print_str("FMC11X DAC init : DONE\n");
    return pass;
}
