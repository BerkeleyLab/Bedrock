#include <stdio.h>
#include <stdbool.h>
#include "print.h"
#include "sfr.h"
#include "timer.h"
#include "i2c_soft.h"
#include "fmc120.h"
#include "common.h"
#include "dsp.h"
#include "settings.h"
#include "gpio.h"

#ifdef _PRINTF
#include "printf.h" // cost 10kB
#endif

/*
 JESD204B subclass1 deterministic latency
 http://www.ti.com/lit/ml/slap159/slap159.pdf
    ADC: ADS54J60
    * LMFS: 4 2 1 1
    * ceil(17/F) ≤ K ≤ min(32, floor(1024/F))
    * choose K = 32
    * 2 lanes at 1Gbps per channel, 2 channels per chip
    * F_LMFC = LineRate / 10 / (F*K) = 31.25MHz
    * F_SYSREF = F_LMFC / 2^N, where N=0,1,2...,
    * F_SYSREF = F_s / 2^N
    * 1MHz < F_SYSREF < 5MHz
    * Choose F_SYSREF = 1GHz / 256 = 31.25 / 8 = 3.90625MHz

    DAC: DAC39J84
    * LMFSK: 8 4 1 1 32
    * 2 lanes at 1Gbps per channel, 4 channels per chip
    * F_LMFC = LineRate / 10 / (F*K) = 31.25MHz
*/

uint32_t g_base_addr = 0;
uint32_t g_base_jesd_sfr = 0;
uint32_t g_base_sfr  = FMC120_BASE2_SFR;

// AIN0:7, Temp
static uint32_t AD7291Values[9];
uint8_t I2C_ADR_FMC120_M24C02;
uint8_t I2C_ADR_FMC120_AD7291;
uint8_t I2C_ADR_FMC120_CPLD;
uint8_t I2C_ADR_FMC120_LTC2657;

uint32_t read_jesd204_axi(uint32_t base_core, uint32_t add) {
    return *(volatile uint32_t*)(g_base_addr + base_core + add);
}

void write_jesd204_axi(uint32_t base_core, uint32_t add, uint32_t val) {
    *((volatile uint32_t*)(g_base_addr + base_core + add)) = val;
}

void FMC120_SetTxEnable(bool enable) {
    SET_SFR1(g_base_sfr, 0, SFR_BIT_DAC_TX_EN, enable);
}

void FMC120_SetTestPatEnable(bool enable) {
    SET_SFR1(g_base_sfr, 0, SFR_BIT_DAC_TP_EN, enable);
}

uint16_t FMC120_GetStatus(void) {
    // from bit 16:
    // #define SFR_BIT_STATUS_PG           16
    // #define SFR_BIT_STATUS_PRSNT_L      17
    // #define SFR_BIT_STATUS_ADC_A_OVER0  18
    // #define SFR_BIT_STATUS_ADC_A_OVER1  19
    // #define SFR_BIT_STATUS_ADC_B_OVER0  20
    // #define SFR_BIT_STATUS_ADC_B_OVER1  21
    return GET_REG16(g_base_sfr + 2);
}

void FMC120_SelectAddr(uint8_t ga, uint32_t base_addr) {
    switch( ga ) {
        case 0x1:
            I2C_ADR_FMC120_M24C02  = 0x52;
            I2C_ADR_FMC120_AD7291  = 0x2C;
            I2C_ADR_FMC120_CPLD    = 0x1D;
            I2C_ADR_FMC120_LTC2657 = 0x22;
            break;
        case 0x2:
            I2C_ADR_FMC120_M24C02  = 0x51;
            I2C_ADR_FMC120_AD7291  = 0x23;
            I2C_ADR_FMC120_CPLD    = 0x1E;
            I2C_ADR_FMC120_LTC2657 = 0x52;
            break;
        case 0x3:
            I2C_ADR_FMC120_M24C02  = 0x53;
            I2C_ADR_FMC120_AD7291  = 0x20;
            I2C_ADR_FMC120_CPLD    = 0x1F;
            I2C_ADR_FMC120_LTC2657 = 0x70;
            break;
        default:
            I2C_ADR_FMC120_M24C02  = 0x50;
            I2C_ADR_FMC120_AD7291  = 0x2F;
            I2C_ADR_FMC120_CPLD    = 0x1C;
            I2C_ADR_FMC120_LTC2657 = 0x10;
    }
    g_base_addr = base_addr;
    g_base_sfr =  base_addr + FMC120_BASE2_SFR;
    g_base_jesd_sfr = base_addr + FMC120_JESD_SFR;
}

void FMC120_PrintStatus(bool status) {
    print_str(status ? "   OK.\n" : "Error.\n");
}

bool FMC120_CheckPrsnt(uint32_t base_addr) {
    uint8_t byte;
    byte = GET_SFR1(base_addr + FMC120_BASE2_SFR, 0, SFR_BIT_STAT_PRSNT_L);
    // active low
    return !(byte & 0x1);
}

bool FMC120_Init(uint8_t clockmode, uint8_t ga, uint32_t base_addr) {
    uint8_t byte;
    bool ret = true;

    // Double check board presence
    ret &= FMC120_CheckPrsnt(base_addr);
    print_str("GA1,GA0       : ");
    print_hex(ga, 1);
    print_str("\n");

    FMC120_SelectAddr(ga, base_addr);
    byte = FMC120_CPLD_GetVer();
    if (byte != 0x10) {
        print_str("ERROR: FMC120 Version Invalid.\n");
        return false;
    } else {
        print_str("FMC120 Ver: ");
        print_hex(byte, 2);
        print_str("\n");
    }

    FMC120_SetTxEnable(false);

    // Reset AD7291
    unsigned char cmd[] = "\x00\x02";
    i2c_write_regs(I2C_ADR_FMC120_AD7291, 0, cmd, 2);
    DELAY_MS(1);

    // Configure the clock tree
    ret &= FMC120_InitClock(clockmode);
    print_str("  --- FMC120 CLK Init ---: ");
    FMC120_PrintStatus(ret);

    // Assert Transceiver Reset
    SET_SFR1(g_base_jesd_sfr, 0, BIT_RX_SYS_RESET, 1);
    SET_SFR1(g_base_jesd_sfr, 0, BIT_TX_SYS_RESET, 1);
    SET_SFR1(g_base_jesd_sfr, 0, BIT_RX_RESET, 1);
    DELAY_MS(5);
    byte = GET_SFR1(g_base_jesd_sfr, 0, BIT_STAT_RXRESET_DONE);
    print_str("PHY RX_RESET_DONE        : ");
    FMC120_PrintStatus(byte & 0x1);
    SET_SFR1(g_base_jesd_sfr, 0, BIT_TX_RESET, 1);
    DELAY_MS(5);
    byte = GET_SFR1(g_base_jesd_sfr, 0, BIT_STAT_TXRESET_DONE);
    print_str("PHY TX_RESET_DONE        : ");
    FMC120_PrintStatus(byte & 0x1);

    // Wait for QPLLs to lock
    DELAY_MS(1);
    byte = GET_SFR1(g_base_jesd_sfr, 0, BIT_STAT_QPLLLOCK_0);
    print_str("QPLL0 locked             : ");
    FMC120_PrintStatus(byte & 0x1);
    byte = GET_SFR1(g_base_jesd_sfr, 0, BIT_STAT_QPLLLOCK_1);
    print_str("QPLL1 locked             : ");
    FMC120_PrintStatus(byte & 0x1);

    // jesd204 cores are properly configured by default.
    ret &= init_jesd204_core();
    print_str("  --- INIT_JESD204_CORE ---: ");
    FMC120_PrintStatus(ret);

    // Configure ADC0 and ADC1
    //ret &= FMC120_InitADC();
    //DELAY_MS(50);

    //ret &= FMC120_InitDAC();

    // The following is moved to system.c for both boards.
    // Synchronize LMFC clock
    //FMC120_LMK04828_SyncAll();

    return ret;
}

uint32_t * FMC120_AD7291_ReadAll(void) {
    uint8_t ret = 1;
    unsigned char cmd[2] = {0, 0};
    uint8_t byteBuf[2];
    uint8_t chan, regAdr;
    for (uint8_t ix=0; ix<=8; ix++) {
        cmd[0] = (ix == 8) ? 0x00 : 1<<ix;
        cmd[1] = (ix == 8) ? 0x80 : 0;
        regAdr = (ix == 8) ? 2 : 1;
        ret &= i2c_write_regs(I2C_ADR_FMC120_AD7291, 0, cmd, 2);
        ret &= i2c_read_regs(I2C_ADR_FMC120_AD7291, regAdr, byteBuf, 2);
        if (!ret) return NULL;
        chan = (byteBuf[0] & 0xF0) >> 4;
        AD7291Values[chan] = (byteBuf[0] & 0xF) << 8 | byteBuf[1];
    }
    return AD7291Values;
}

void FMC120_PrintMonitor(uint32_t *data) {
    uint8_t scale, chan, nBit=12;
    const char * unit = " Volt";
#ifdef _PRINTF
    float fvalue;
    for (chan=0; chan<=8; chan++) {
        switch (chan) {
            case 7:
                fvalue = (2048-data[chan]) * 6.6 / 0xfff;
                printf("Vin7    : %8.3f V\n", fvalue);
                break;
            case 8:
                fvalue = data[chan] / 4;
                printf("Temp    : %8.3f degC\n", fvalue);
                break;
            default:
                scale = (chan < 4) ? 5 : 10;
                fvalue = data[chan] * scale / 0x1fff;
                printf("Vin%d    : %8.3f V\n", chan, fvalue);
        }
    }
#else
    for (chan=0; chan<=8; chan++) {
        print_str("FMC120 ");
        switch (chan) {
            case 7:
                // FS is -3.3 to 3.3, 12bits. Use 6.6*32/(1<<17)
                print_str("Vin ");
                print_dec(chan);
                print_str("  :  -");
                data[chan] = (2048 - data[chan]);
                scale = 211; //6.6*32=211.2
                nBit = 17; // 12 + 5;
                break;
            case 8:
                print_str("Temp   : +");
                scale = 1;
                nBit = 2;
                unit = " degC";
                break;
            default:
                print_str("Vin ");
                print_dec(chan);
                print_str("  :  +");
                scale = (chan < 4) ? 5 : 10;
                nBit = 13; // 12 + 1;
                unit = " Volt";
        }
        print_dec_fix( data[chan]*scale, nBit, 2 );
        print_str(unit);
        print_str("\n");
    }
#endif
}

uint8_t FMC120_CPLD_GetVer(void) {
    uint8_t ver;
    i2c_read_regs( I2C_ADR_FMC120_CPLD, CPLD_ADR_VERSION, &ver, 1 );
    return ver;
}

bool FMC120_LMK04828_Reset(void) {
    bool ret = true;
    uint8_t byteBuf;
    ret &= i2c_read_regs( I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);
    // reset
    byteBuf |= 0x01;
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);
    // clear reset
    byteBuf &= 0xFE;
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);
    return ret;
}

bool FMC120_SPI_AssemData(uint16_t spi_select, uint16_t spi_addr, uint16_t spi_dat, DataDword *data) {
    switch (spi_select) {
    case LMK_SELECT:
        data->value = (spi_addr & 0x1FFF) << 8;         // Address is in bits 20 downto 8
        data->value |= spi_dat & 0xFF;                  // 8 bit data
        break;
    case DAC_SELECT:
        data->value = (spi_addr & 0x7F) << 16;          // Address is in bits 22 downto 16
        data->value |= spi_dat & 0xFFFF;                // 16 bit data
        break;
    case ADC0_SELECT: case ADC1_SELECT: case ADC_SELECT_BOTH:
        data->value = (spi_addr & 0x7FFF) << 8;         // Address is in bits 22 downto 8
        data->value |= spi_dat & 0xFF;                  // 8 bit data
        break;
    default:
        print_str("Unsupported SPI write access\n");
        data->value = 1<<23;
        return false;
    }
    return true;
}

bool FMC120_SPI_Write(uint8_t spi_select, uint16_t spi_addr, uint16_t spi_dat) {
    bool ret = true;
    DataDword data;

    ret &= FMC120_SPI_AssemData(spi_select, spi_addr, spi_dat, &data);
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_SPI_WDAT0, &data.bytes[0], 1);
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_SPI_WDAT1, &data.bytes[1], 1);
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_SPI_WDAT2, &data.bytes[2], 1);
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_COMMAND,   &spi_select, 1);
    return ret;
}

bool FMC120_SPI_Read(uint8_t spi_select, uint16_t spi_addr, uint16_t *spi_dat) {
    DataDword data;
    DataWord rdata;
    bool ret = true;

    ret &= FMC120_SPI_AssemData(spi_select, spi_addr, 0, &data);
    data.value |= 1<<23; // read

    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_SPI_WDAT0, &data.bytes[0], 1);
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_SPI_WDAT1, &data.bytes[1], 1);
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_SPI_WDAT2, &data.bytes[2], 1);
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_COMMAND,   &spi_select, 1);
    ret &= i2c_read_regs (I2C_ADR_FMC120_CPLD, CPLD_ADR_SPI_RDAT0, &rdata.bytes[0], 1);
    ret &= i2c_read_regs (I2C_ADR_FMC120_CPLD, CPLD_ADR_SPI_RDAT1, &rdata.bytes[1], 1);
    *spi_dat = rdata.value;

    return ret;
}

bool FMC120_SPI_WriteRegs(uint8_t spi_select, t_reg16 *regmap, size_t len) {
    bool ret = true;
    while ( len-- > 0 ){
        ret &= FMC120_SPI_Write(spi_select, regmap->addr, regmap->data);
        regmap++;
    }
    return ret;
}

bool FMC120_CPLD_Control0(bool enable, uint8_t bitAddr) {
// bitAddr: osc100 =0, osc500=1
    uint8_t byteBuf, bitMask;
    bool ret = true;
    bitMask = 1 << bitAddr;

    // Read, Modify, Write to avoid clobbering any other register settings
    ret = i2c_read_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL0, &byteBuf, 1);
    if (enable) {
        byteBuf |= bitMask; // Set enable bit
    } else {
        byteBuf &= ~bitMask; // Clear enable bit
    }
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL0, &byteBuf, 1);

    return ret;
}

bool FMC120_InitClock(uint8_t clockmode) {
    bool ret;
    ret = FMC120_LMK04828_Reset();                      // Reset clock chip

    if (clockmode == FMC120_INTERNAL_CLK) {
        print_str("    Using Internal Clock.\n") ;
        FMC120_CPLD_Control0(true, OSC100_EN_ADR);
        print_str("    100 MHz OSC ON\n") ;
        FMC120_CPLD_Control0(true, OSC500_EN_ADR);
        print_str("    500 MHz VCSO ON\n");

        t_reg16 regmap[] = {
            { 0x000, 0x80 },      // Force Reset
            { 0x000, 0x00 },      // Clear Reset
            { 0x000, 0x10 },      // Force SPI to be 4-Wire
            { 0x148, 0x33 },      // CLKIN_SEL0_MUX Configured as LMK MISO Push Pull Output
            { 0x002, 0x00 },      // POWERDOWN Disabled (Normal Operation)

            // CLK0/1 Settings  DAC 1GHz
            { 0x100, 0x63 },     // DIV_CLKOUT1_0 DIV_BY_3 = 1GHz, IDL/ODL == 1  ==> In/Out Drive level = higher
            { 0x101, 0x22 },     // DIG_DLY_DCLK0 Digital Delay
            { 0x103, 0x05 },     // ANA_DLY_DCLK2 No Analog Delay, Half step duty cycle correction, 50% Duty Cycle!  (DAC Spec id 40 -/ 60% MAX)
            { 0x104, 0x62 },     // DIG_DLY_SCLK1 DCLK halfstep=-0.5, SCLK sourced from DCLK,  2 vco clock cycle delay on sysref out
            { 0x105, 0x00 },     // ANA_DLY_SCLK1 SCLK analog delay disabled
            { 0x106, 0xB0 },     // PD_CLK1_0 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x107, 0x55 },     // Dclk =LVPECL, Sclk = LVPECL, !DCLK_INV, !SCLK_INV

            // CLK2/3 Settings  Output to FPGA
            { 0x108, 0x6C },     // DIV_CLKOUT  DIV_CLKOUT1_0 DIV_BY_3 = 1GHz, IDL/ODL == 1  ==> In/Out Drive level = higher
            { 0x109, 0x22 },     // DIG_DLY_DCLK0 Digital Delay
            { 0x10B, 0x05 },     // ANA_DLY_DCLK2 No Analog Delay, Half step duty cycle correction, 50% Duty Cycle!  (DAC Spec id 40 -/ 60% MAX)
            { 0x10C, 0x62 },     // DIG_DLY_SCLK3  DCLK halfstep=-0.5, SCLK sourced from DCLK,  2 vco clock cycle delay on sysref out
            { 0x10D, 0x0A },     // ANA_DLY_SCLK3  SCLK analog delay disabled
            { 0x10E, 0xB0 },     // PD_CLK2/3 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x10F, 0x11 },     // FMT_CLK3_3 Dclock = LVPECL, Sclock = LVPECL !DCLK_INV, !SCLK_INV

            // CLK4/5 Settings  ADCB 1GHz
            { 0x110, 0x63 },     // DIV_CLKOUT5_4  DIV_BY_3 = 1GHz, IDL/ODL= 1  ==>In/Out Drive level = higher
            { 0x111, 0x22 },     // DIG_DLY_DCLK0 Digital Delay
            { 0x113, 0x05 },     // ANA_DLY_DCLK4 No Analog Delay, Half step duty cycle correction, 50% Duty Cycle!  (DAC Spec id 40 -/ 60% MAX)
            { 0x114, 0x62 },     // DIG_DLY_SCLK5 DCLK halfstep=-0.5, SCLK sourced from DCLK,  2 vco clock cycle delay on sysref out
            { 0x115, 0x00 },     // ANA_DLY_SCLK5 SCLK analog delay disabled
            { 0x116, 0xB0 },     // PD_CLK5_4 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x117, 0x57 },     // DIV_CLKOUT5_4     Dclk =LVPECL, Sclk =LVPECL, !DCLK_INV, !SCLK_INV

            // CLK6/7 Settings  ADCA 1GHz
            { 0x118, 0x63 },     // DIV_CLKOUT7_6     DIV_BY_3 = 1GHz, IDL/ODL= 1  ==>In/Out Drive level
            { 0x119, 0x22 },     // DIG_DLY_DCLK0 Digital Delay
            { 0x11B, 0x05 },     // ANA_DLY_DCLK6 No Analog Delay, Half step duty cycle correction, 50% Duty Cycle!  (DAC Spec id 40 -/ 60% MAX)
            { 0x11C, 0x62 },     // DIG_DLY_SCLK7 DCLK halfstep=-0.5, SCLK sourced from DCLK,  2 vco clock cycle delay on sysref out
            { 0x11D, 0x00 },     // ANA_DLY_SCLK7   SCLK analog delay disabled
            { 0x11E, 0xB0 },     // PD_CLK7_6 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x11F, 0x57 },     // DIV_CLKOUT7_6    Dclk =LVPECL, Sclk =LVPECL, !DCLK_INV, !SCLK_INV

            { 0x120, 0x66 },    // DIV_CLKOUT9_8       // DIV_BY_3 = 1GHz, IDL/ODL= 1  ==>In/Out Drive level normal
            { 0x121, 0x22 },    // DIG_DLY_DCLK0 Digital Delay
            { 0x123, 0x05 },    // ANA_DLY_DCLK8    No Analog Delay, Half step duty cycle correction, 50% Duty Cycle!  (DAC Spec id 40 -/ 60% MAX)
            { 0x124, 0x62 },    // DIG_DLY_SCLK9   DCLK halfstep=-0.5, SCLK sourced from DCLK,  2 vco clock cycle delay on sysref out
            { 0x125, 0x00 },    // ANA_DLY_SCLK9   SCLK analog delay disabled
            { 0x126, 0xB7 },    // PD_CLK9_8 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x127, 0x11 },    // Sclk OFF   Dclock = LVDS

            // CLK10/11 Settings  DCLK 10 (LMK_DCLK10_M2C_TO_FPGA_P) this clock drives GBTCLK0M2C_PN FMC pins B20,B21
            { 0x128, 0x66 },    // DIV_CLKOUT11_10       // DIV_BY_3 = 1GHz, IDL/ODL= 1  ==>In/Out Drive level normal
            { 0x129, 0x22 },    // DIG_DLY_DCLK0     Digital Delay
            { 0x12B, 0x05 },    // ANA_DLY_DCLK10  No Analog Delay, Half step duty cycle correction, 50% Duty Cycle!  (DAC Spec id 40 -/ 60% MAX)
            { 0x12C, 0x62 },    // DIG_DLY_SCLK11     DCLK halfstep=-0.5, SCLK sourced from DCLK,  2 vco clock cycle delay on sysref out
            { 0x12D, 0x00 },    // ANA_DLY_SCLK11    SCLK analog delay disabled
            { 0x12E, 0xB7 },    // PD_CLK11_10 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, SCLK Disabled at VCM
            { 0x12F, 0x11 },    // Both Off, iff enbaled with pop option use  0X01: Sclock OFF Dclock = LVDS

            // External Clock Output, This will be programed 'on' but we will Clear it off in final configuration
            // CLK12/13 Settings  DCLK 12 EXTERNAL CLOCK OUTPUT
            { 0x130, 0x63 },    // DIV_CLKOUT13_12  / DIV_BY_3 = 1GHz, IDL/ODL= 1  ==>In/Out Drive level normal
            { 0x131, 0x22 },    // DIG_DLY_DCLK0     Digital Delay
            { 0x133, 0x05 },    // ANA_DLY_DCLK12     No Analog Delay, Half step duty cycle correction, 50% Duty Cycle!  (DAC Spec id 40 -/ 60% MAX)
            { 0x134, 0x62 },    // DIG_DLY_SCLK13    SCLK analog = 2 VCO Clock Cycles (666pS << from FMC144 )
            { 0x135, 0x00 },    // ANA_DLY_SCLK13    SCLK analog delay disabled
            { 0x136, 0xB7 },    // PD_CLK13_12 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, SCLK Disabled at VCM
            { 0x137, 0x00 },    // Sclk Off, Dclock On = LVPECL                << set to 0x00 to turn off Externl Clock option

            // Select VCO1 PLL1 source
            { 0x138, 0x20 },    // VCO_OSC_OUT VCO01 (High Speed), PLL1_FB=OSCin,OSCOUT=input (Drivers powerd down)
            { 0x139, 0x03 },    // SYSREF_MUX SYSREF output source = Normal Sync     start with 0 reprogram when turning on sysref
            { 0x13A, 0x06 },    // SYSREF_DIV(MS) SYSREF Divider
            { 0x13B, 0x00 },    // SYSREF_DIV(LS) SYSREF Divider
            { 0x13C, 0x00 },    // SYSREF_DDLY(MS) SYSREF Digital Delay  - Not Used
            { 0x13D, 0x08 },    // SYSREF_DDLY(LS) SYSREF Digital Delay  - Not Used

            { 0x13E, 0x00 },    // SYSREF_PULSE_CNT 8 Pulses - Not Used
            { 0x13F, 0x00 },    // FB_CTRL PLL2_FB=prescaler, PLL1_FB=OSCIN   This is default for internal Oscillator, this changes on EXT osc
            { 0x140, 0x01 },    // OSCIN_SYSREF_PD Active= PLL1, LDO, VCO, OSCIN, SYSREF
            { 0x141, 0x00 },    // DIG_DLY_REG Disable all digital delays
            { 0x142, 0x00 },    // DIG_DLY_STEP_CNT No Adjustment of Digital Delay
            { 0x143, 0x70 },    // SYNC_SYSREF SYNC functionality enabled, prevent SYNC pin and DLD flags from generating SYNC event
                                // DCLK12, DCLK10, DCLK8 do not re-sync during a sync event
            { 0x144, 0xFF },    // DISABLE_DCLK_SYNC Prevent SYSREF clocks from synchronizing
            { 0x145, 0x7F },    // FIXED Always 0x7F
            { 0x146, 0x00 },    // CLKIN_SRC No AutoSwitching of clock inputs, all 3 CLKINx pins are set t0 Bipolar,

            // Internal Reference
            { 0x147, 0x2A },   // Internal: CLKIN_MUX CLKIN = clkin1 (External Reference connector), !INVERT, CLKIN1=PLL1, CLKIN0=SYSREF MUX

            { 0x148, 0x33 },    // CLKIN_SEL0_MUX Configured as LMK MISO Push Pull Output
            { 0x149, 0x00 },    // CLKIN_SEL1_MUX SPI SDIO_readback = PUSH-PULL !! CLKIN_SEL1=input
            { 0x14A, 0x00 },    // RESET_MUX RESET Pin=Input
            { 0x14B, 0x05 },    // Holdover mode off Manual DAC Enabled
            { 0x14C, 0xFF },    // MANUAL_DAC Force DAC to midscale 0x01FF
            { 0x14D, 0x00 },    // DAC_TRIP_LOW Min Voltage to force HOLDOVER
            { 0x14E, 0x00 },    // DAC_TRIP_HIGH Mult=4 Max Voltage to force HOLDOVER
            { 0x14F, 0x7F },    // DAC_UPDATE_CNTR
            { 0x150, 0x00 },    // HOLDOVER_SET HOLDOVER disable
            { 0x151, 0x02 },    // HOLD_EXIT_COUNT(MS)
            { 0x152, 0x00 },    // HOLD_EXIT_COUNT(LS)

            //PLL1 CLKIN0 Divider, FMC120 trigger mux feeds this input
            { 0x153, 0x00 },    // CLKIN0_DIV (MS)
            { 0x154, 0x78 },    // CLKIN0_DIV (LS)

            // External Reference Input
            //PLL1 CLKIN1 Divider External Reference input, default 100MHz and a 100.000KHz Phase Detector Frequency
            { 0x155, 0x00 },    // CLKIN1_DIV (MS)      100MHz / 1000 = 100KHz
            { 0x156, 0X0A },    // CLKIN1_DIV (LS)

            // *********** PLL 1 REF Set      // 10MHz
            // onboard 100MHz Oscillator at LMK OSCOUT pins
            //PLL1 CLKIN2 Divider, divides onboard 100MHz Ref Osc output down to Phase Detector Frequency
            { 0x157, 0x00 },    // CLKIN2_DIV (MS)         R divide = A = 10 = 10MHz
            { 0x158, 0x0A },    // CLKIN2_DIV (LS)

            // Onbaord 500MHz VCSO at LMK OSCIN pins
            // PLL1 N divider, Divide 500MHz VCSO down to PDF
            { 0x159, 0x00 },    // PLL1_NDIV (MS)  N divide =0x32 = 50 = 10 MHz
            { 0x15A, 0x32 },    // PLL1_NDIV (LS)

            // PLL1 Coonfiguration
            { 0x15B, 0xDF },    // PLL1_SETUP,  Dlig lock det window 43ns, PLL active, Pos Slope, max pump current
            { 0x15C, 0x20 },    // PLL1_LOCK_CNT (MS)    Lock detector window,  must be valid for 1024 cycles
            { 0x15D, 0x00 },    // PLL1_LOCK_CNT (LS)
            { 0x15E, 0x00 },    // PLL1_DLY   // not applicable keep at 0
            { 0x15F, 0x0B },    // STATUS_LD1_MUX == LD1 Push-Pull Output

            // PLL2 onfigured to lock VCO1 at 3000MHz to 500MHz VCSO with a PFD of 125MHz, (4N * 6P = 24) * 125MHz = 3000MHz
            //a prescale value of 6 allows the PLL2 N and R to match
            { 0x160, 0x00 },    // PLL2_RDIV (MS) PLL2 Reference Divider = 4 refference frequency = 125MHz
            { 0x161, 0x04 },    // PLL2_RDIV (LS)
            { 0x162, 0xD0 },    // PLL2_PRESCALE PRE=6,  >255 to 500MHz  range  amp off, doubler off
            { 0x163, 0x00 },    // PLL2_NCAL (HI) Only used during CAL
            { 0x164, 0x00 },    // PLL2_NCAL (MID)
            { 0x165, 0x04 },    // PLL2_NCAL (LOW)

            { 0x145, 0x7F },      // always 127 / 0x7F
            { 0x171, 0xAA },      //
            { 0x172, 0x02 },      //
            { 0x17C, 0x15 },      // OPT_REG1
            { 0x17D, 0x33 },      // OPT_REG2

            { 0x166, 0x00 },      // PLL2_NDIV (HI) Allow CAL
            { 0x167, 0x00 },      // PLL2_NDIV (MID) PLL2 N-Divider
            { 0x168, 0x04 },      // PLL2_NDIV (LOW) Cal. P = 3, N = 8 (24 * 125Mhz_ref = 3G)
            { 0x169, 0x49 },      // PLL2_SETUP Window 3.7nS, I(cp)=1.6mA, Pos Slope, CP ! Tristate, Bit 0 always 1. 1.6mA gives better close in phase  noise than 3.2mA.
            { 0x16A, 0x00 },      // PLL2_LOCK_CNT (MS)
            { 0x16B, 0x20 },      // PLL2_LOCK_CNT (LS)  PD must be in lock for 16 cycles
            { 0x16C, 0x00 },      // PLL2_LOOP_FILTER_R Disable Internal, uses externla Loop Filter R3=R4=200 Ohms
            { 0x16D, 0x00 },      // PLL2_LOOP_FILTER_C Disable Internal, uses externla Loop Filter C3=C4=10 pF
            { 0x16E, 0x12 },      // STATUS_LD2_MUX LD2=Locked   Push Pull Output
            { 0x173, 0x00 }       // PLL2_MISC PLL2 Active, normal opperation
        };

        ret &= FMC120_SPI_WriteRegs(LMK_SELECT, regmap, sizeof(regmap) / sizeof(regmap[0]));

        DELAY_MS(10);   // Wait PLL to lock
        t_reg16 regmap2[] = {
            // Clear PLL1 Errors regardless of if we use them
            { 0x182, 0x01 },
            { 0x182, 0x00 },

            // Clear PLL2 Erros regardless of if we use them
            { 0x183, 0x01 },
            { 0x183, 0x00 }
        };
        ret &= FMC120_SPI_WriteRegs(LMK_SELECT, regmap2, sizeof(regmap2) / sizeof(regmap2[0]));

        uint16_t spi_read_dat[2];
        DELAY_MS(50);        //    Look for 50ms to see if PLL is unlocked

        // verify PLL1 status
        ret &= FMC120_SPI_Read(LMK_SELECT, 0x182, &spi_read_dat[0]);

        // verify PLL2 status
        ret &= FMC120_SPI_Read(LMK_SELECT, 0x183, &spi_read_dat[1]);
        ret &= CHECK_BIT(spi_read_dat[0], 1) && CHECK_BIT(spi_read_dat[1], 1);
        print_str("PLL Locked              : ");
        FMC120_PrintStatus(ret);

    } else if (clockmode == FMC120_EXTERNAL_CLK) {

        print_str("    Using External Clock.\n") ;
        FMC120_CPLD_Control0(false, OSC100_EN_ADR);
        print_str("    100 MHz OSC OFF\n") ;
        FMC120_CPLD_Control0(false, OSC500_EN_ADR);
        print_str("    500 MHz VCSO OFF\n");

        // SYNCSRC_SEL[1:0] = 1, SYNC_FROM_FPGA_P/N, FMC120 Manual Fig 9
        uint8_t byteBuf = 0;
        print_str("    Setting SYNCSRC_SEL[1:0] = 0\n");
        i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);
        i2c_read_regs( I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);
        print_str("    CPLD_ADR_CONTROL2: 0x");
        print_hex(byteBuf, 2);
        print_str("\n");

        // datasheet table 2.
        // SYNC_MODE:  0: Prevent SYNC pin. 1: From SYNC pin. 2: From Pulser via SYNC pin. 3: From Pulser via SPI
        // SYSREF_MUX: 0: Normal SYNC. 1: Re-clocked. 2: SYSREF Pulser. 3: SYSREF Continous
        uint8_t sync_mode = 1;
        uint8_t sysref_mux = 0;
        uint8_t sysref_clkin0_mux = 0; // XXX 1 not working
        uint8_t sysref_clr = 1;

        t_reg16 regmap[] = {
            { 0x000, 0x80 },    // Force Reset
            { 0x000, 0x00 },    // Clear Reset
            { 0x000, 0x10 },    // Force SPI to be 4-Wire
            { 0x002, 0x00 },    // POWERDOWN Disabled (Normal Operation)
            // CLK0/1 Settings  DAC 1GHz
            { 0x100, 0x61 },    // DIV_CLKOUT1_0 DIV_BY_1 = 1GHz, IDL/ODL == 1  ==> In/Out Drive level = higher
            { 0x103, 0x02 },    // DCLKout0_MUX = Bypass
            { 0x104, 0x20 },    // SDCLKoutX_MUX=1
            { 0x105, 0x00 },    // ANA_DLY_SCLK1 SCLK analog delay disabled
            { 0x106, 0xF0 },    // PD_CLK1_0 !DIG_DLY, GLITCHLESS Half Step OFF, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x107, 0x55 },    // Dclk =LVPECL, Sclk = LVPECL, !DCLK_INV, !SCLK_INV

            // CLK2/3 Settings  Output to FPGA
            { 0x108, 0x64 },    // DIV_CLKOUT  DIV_CLKOUT1_0 DIV_BY_4 = 0.25GHz, IDL/ODL == 1  ==> In/Out Drive level = higher
            { 0x109, 0x22 },    // DIG_DLY_DCLK0 Digital Delay
            { 0x10B, 0x05 },    // Divided with duty cycle correction
            { 0x10C, 0x20 },    // DIG_DLY_SCLK3  DCLK halfstep=-0.5, SCLK sourced from DCLK,  2 vco clock cycle delay on sysref out ???
            { 0x10D, 0x00 },    // ANA_DLY_SCLK3  SCLK analog delay disabled
            { 0x10E, 0xB0 },    // PD_CLK2/3 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x10F, 0x11 },    // FMT_CLK3_3 Dclock = LVDS, Sclock = LVDS, !DCLK_INV, !SCLK_INV

            // CLK4/5 Settings  ADCB 1GHz
            { 0x110, 0x61 },    // DIV_CLKOUT5_4  DIV_BY_1 = 1GHz, IDL/ODL= 1  ==>In/Out Drive level = higher
            { 0x113, 0x02 },    // DCLKout4_MUX = Bypass
            { 0x114, 0x20 },    // SDCLKoutX_MUX=1
            { 0x115, 0x00 },    // ANA_DLY_SCLK5 SCLK analog delay disabled
            { 0x116, 0xF0 },    // PD_CLK5_4 !DIG_DLY, GLITCHLESS Half Step OFF, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x117, 0x57 },    // DIV_CLKOUT5_4     Dclk =LVPECL, Sclk =LVPECL, !DCLK_INV, !SCLK_INV

            // CLK6/7 Settings  ADCA 1GHz
            { 0x118, 0x61 },    // DIV_CLKOUT7_6     DIV_BY_1 = 1GHz, IDL/ODL= 1  ==>In/Out Drive level
            { 0x11B, 0x02 },    // DCLKout6_MUX = Bypass
            { 0x11C, 0x20 },    // SDCLKoutX_MUX=1
            { 0x11D, 0x00 },    // ANA_DLY_SCLK7   SCLK analog delay disabled
            { 0x11E, 0xF0 },    // PD_CLK7_6 !DIG_DLY, GLITCHLESS Half Step OFF, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x11F, 0x57 },    // DIV_CLKOUT7_6    Dclk =LVPECL, Sclk =LVPECL, !DCLK_INV, !SCLK_INV

            // CLK8/9 Settings  Output to FPGA for GTX refclk 0.5GHz
            { 0x120, 0x62 },    // DIV_CLKOUT9_8       // DIV_BY_2 = 0.5GHz, IDL= 1
            { 0x123, 0x05 },    // Divided with duty cycle correction
            { 0x124, 0x20 },    // DIG_DLY_SCLK9   DCLK halfstep=-0.5, SCLK sourced from DCLK,  2 vco clock cycle delay on sysref out ???
            { 0x125, 0x00 },    // ANA_DLY_SCLK9   SCLK analog delay disabled
            { 0x126, 0xB0 },    // PD_CLK9_8 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, EN_SCLK
            { 0x127, 0x11 },    // Sclk OFF   Dclock = LVDS

            // CLK10/11 Settings  DCLK 10 (LMK_DCLK10_M2C_TO_FPGA_P) this clock drives GBTCLK0M2C_PN FMC pins B20,B21
            { 0x128, 0x62 },    // DIV_CLKOUT11_10       // DIV_BY_2 = 0.5GHz, IDL= 1
            { 0x12B, 0x02 },    // bypass
            { 0x12C, 0x20 },    // SDCLKoutX_MUX=1
            { 0x12D, 0x00 },    // ANA_DLY_SCLK11    SCLK analog delay disabled
            { 0x12E, 0xF7 },    // PD_CLK11_10 !DIG_DLY, GLITCHLESS Half Step OFF, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, SCLK Disabled at VCM
            { 0x12F, 0x00 },    // Both Off, iff enbaled with pop option use  0X01: Sclock OFF Dclock = LVDS

            // External Clock Output, This will be programed 'on' but we will Clear it off in final configuration
            // CLK12/13 Settings  DCLK 12 EXTERNAL CLOCK OUTPUT
            { 0x130, 0x61 },    // DIV_CLKOUT13_12  / DIV_BY_3 = 1GHz, IDL/ODL= 1  ==>In/Out Drive level normal
            { 0x133, 0x02 },    // DCLKout12_MUX = Bypass
            { 0x134, 0x20 },    // SDCLKoutX_MUX=1
            { 0x135, 0x00 },    // ANA_DLY_SCLK13    SCLK analog delay disabled
            { 0x136, 0xF7 },    // PD_CLK13_12 !DIG_DLY, GLITCHLESS Half Step ON, !ANAGLITCH, !ANA_DLY, EN_DCLK, ACTIVE, SCLK Disabled at VCM
            { 0x137, 0x00 },    // Sclk Off, Dclock On = LVPECL                << set to 0x00 to turn off Externl Clock option

            // VCO MUX
            { 0x138, 0x40 },    // VCO_MUX = CLKin1, powerdown CLKin2
            { 0x139, (sysref_clkin0_mux << 2) | sysref_mux },    // SYSREF_MUX
            { 0x13A, 0x01 },    // SYSREF_DIV(MS) SYSREF Divider
            { 0x13B, 0x00 },    // SYSREF_DIV(LS) SYSREF Divider 1GHz/(0x100)=3.906MHz
            { 0x13C, 0x00 },    // SYSREF_DDLY(MS) SYSREF Digital Delay  - Not Used
            { 0x13D, 0x08 },    // SYSREF_DDLY(LS) SYSREF Digital Delay  - Not Used

            // DAC requires at least 2 Pulses of sysref, see SLAA696 section 4.1
            // { 0x13E, 0x03 },    // SYSREF_PULSE_CNT 8 Pulses
            { 0x13E, 0x02 },    // SYSREF_PULSE_CNT 4 Pulses
            // { 0x13E, 0x01 },    // SYSREF_PULSE_CNT 2 Pulses
            // { 0x13E, 0x00 },    // SYSREF_PULSE_CNT 1 Pulses
            { 0x13F, 0x00 },    // FB_CTRL PLL2_FB=prescaler, PLL1_FB=OSCIN   This is default for internal Oscillator, this changes on EXT osc
            { 0x140, 0xf0 },    // SYSREF_GBL_PD=0, SYSREF_PD=0, SYSREF_DDLY_PD=0, SYSREF_PLSR_PD=0
            { 0x141, 0x00 },    // DIG_DLY_REG Disable all digital delays
            { 0x142, 0x00 },    // DIG_DLY_STEP_CNT No Adjustment of Digital Delay
            { 0x143, (sysref_clr << 7) | 0x10 | sync_mode },    // SYSREF_CLR=1, SYNC_EN=1, SYNC_MODE=sync_mode
            { 0x143, (sysref_clr << 7) | 0x10 | sync_mode },    // SYSREF_CLR=1, SYNC_EN=1, SYNC_MODE=sync_mode
                                // DCLK12, DCLK10, DCLK8 do not re-sync during a sync event
            { 0x143, 0x10 | sync_mode },    // SYSREF_CLR=0, SYNC_EN=1, SYNC_MODE=sync_mode
            { 0x144, 0x60 },    // ENABLE SYNC to reset all dividers, SYNC_DIS[SYSREF/8/6/4/2/0]
            { 0x145, 0x7F },    // FIXED Always 0x7F
            { 0x146, 0x00 },    // CLKIN_SRC No AutoSwitching of clock inputs, all 3 CLKINx pins are set t0 Bipolar,

            // External reference
            { 0x147, 0x10 },   // External: CLKin_SEL_MODE = CLKin1 Manual, CLKin1_OUT_MUX = Fin, CLKin0_OUT_MUX = SYSREF_MUX

            { 0x148, 0x33 },    // CLKIN_SEL0_MUX Configured as LMK MISO Push Pull Output
            { 0x149, 0x00 },    // CLKIN_SEL1_MUX SPI SDIO_readback = PUSH-PULL !! CLKIN_SEL1=input
            { 0x14A, 0x00 },    // RESET_MUX RESET Pin=Input
            { 0x14B, 0x05 },    // Holdover mode off Manual DAC Enabled
            { 0x14C, 0xFF },    // MANUAL_DAC Force DAC to midscale 0x01FF
            { 0x14D, 0x00 },    // DAC_TRIP_LOW Min Voltage to force HOLDOVER
            { 0x14E, 0x00 },    // DAC_TRIP_HIGH Mult=4 Max Voltage to force HOLDOVER
            { 0x14F, 0x7F },    // DAC_UPDATE_CNTR
            { 0x150, 0x00 },    // HOLDOVER_SET HOLDOVER disable
            { 0x151, 0x02 },    // HOLD_EXIT_COUNT(MS)
            { 0x152, 0x00 },    // HOLD_EXIT_COUNT(LS)

            /*
            // Table 2, direct dist.
            { 0x139, 0x04 },    // SYSREF_CLKin0_MUX = 1, SYSREF_MUX = 0
            { 0x140, 0xf7 },    // SYSREF_PD=1, SYSREF_DDLY_PD=1, SYSREF_PLSR_PD=1
            // Table 2, line3.
            { 0x139, 0x01 },    // SYSREF_CLKin0_MUX = 0, SYSREF_MUX = 1
            { 0x140, 0xf3 },    // SYSREF_PD=0
            */
            { 0x171, 0xAA },     //
            { 0x172, 0x02 },     //
            { 0x17C, 0x15 },     // OPT_REG1
            { 0x17D, 0x33 },     // OPT_REG2
            { 0x173, 0x60 }      // power down PLL2
        };
        ret &= FMC120_SPI_WriteRegs(LMK_SELECT, regmap, sizeof(regmap) / sizeof(regmap[0]));

        //    2.(e) Perform SYNC by toggling SYNC_POL
        //    Moved to upper level to apply to both boards simutanously.
        // FMC120_LMK04828_SyncAll();
        // FMC120_LMK04828_SetSYSREF();
    }
    DELAY_MS(10);

    return ret;
}

bool FMC120_LMK04828_SetSYSREF(void) {
    uint8_t sync_mode = 2;
    uint8_t sysref_mux = 2; // 3 for continous sysref
    uint8_t sysref_clr = 0;
    uint8_t sysref_clkin0_mux = 0;

    // Release reset of local SYSREF digital delay
    uint16_t reg143 = (sysref_clr << 7) | 0x10 | sync_mode;
    FMC120_SPI_Write(LMK_SELECT, 0x143, reg143);

    t_reg16 regmap[] = {
        // 3. Disable SYNC from resetting dividers:
        { 0x144, 0xFF },
        // 4. Release reset of local SYSREF digital delay.
        { 0x143, (sysref_clr << 7) | 0x10 | sync_mode },
        // 5. Set SYSREF operation.
        { 0x139, (sysref_clkin0_mux << 2) | sysref_mux },    // SYSREF_MUX
    };
    return FMC120_SPI_WriteRegs(LMK_SELECT, regmap, sizeof(regmap) / sizeof(regmap[0]));
}

bool FMC120_DAC39J84_Reset(void) {
    // Ch0-3 Amplifier On, No Sleep
    bool ret = true;
    uint8_t byte = 0;
    // Assert reset (active-LOW)
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL1, &byte, 1);
    byte = 0x20;
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL1, &byte, 1);
    return ret;
}

bool FMC120_ShortPatternTest(void) {
    bool ret = true;
    uint16_t spi_read_dat;
    uint16_t reg02 = 0x0082;     // twos=1, sif4_ena = 1, zero_invalid_data=0

    ret &= FMC120_SPI_Write(DAC_SELECT, 0x6C, 0x0000);
	// 15-8 : alarm_from_shortest  bit8 = lane0 alarm, bit1 = lane1_alarm
	// 7-0  : Loss of signal dectect outputs from SerDes lanes
    ret &= FMC120_SPI_Read(DAC_SELECT, 0x6C, &spi_read_dat);
    print_str("0x6C = ");
    print_hex(spi_read_dat, 4);
    print_str("\n");

    FMC120_SetTxEnable(false);
    FMC120_SetTestPatEnable(true);

    DELAY_MS(5);

    ret &= FMC120_SPI_Write(DAC_SELECT, 0x02, reg02 | (1<<12));
	// Enable alarms for short pattern test
    ret &= FMC120_SPI_Write(DAC_SELECT, 0x06, 0x00FF);
    DELAY_MS(10);
    ret &= FMC120_SPI_Read(DAC_SELECT, 0x6D, &spi_read_dat);
    print_str("DAC Short Pattern       : ");
    print_hex(spi_read_dat, 4);
    //spi_read_dat &= 0xFF00;
    FMC120_PrintStatus(spi_read_dat == 0x0000);

    // Force Error
    FMC120_SetTestPatEnable(false);
    ret &= FMC120_SPI_Read(DAC_SELECT, 0x6D, &spi_read_dat);
    DELAY_MS(20);
    print_str("DAC Short Pattern Inject: ");
    print_hex(spi_read_dat, 4);
    //spi_read_dat &= 0xFF00;
    FMC120_PrintStatus(spi_read_dat == 0xFF00);

    // Disable short test pattern test
    ret &= FMC120_SPI_Write(DAC_SELECT, 0x02, reg02);
    return ret;
}

bool FMC120_InitDAC(void) {
    bool ret = true;
    uint16_t spi_read_dat;

    // Follow datasheet 8.3
    // 1. Turn off dac output
    FMC120_SetTxEnable(false);

    // 5 Perform hardware reset on DAC39J84 IC
    FMC120_DAC39J84_Reset();

    // DAC SPI: zero_invalid_data=1, sif4_ena=1, twos=1
    ret &= FMC120_SPI_Write(DAC_SELECT, 0x02, 0x2082);
    ret &= FMC120_SPI_Read(DAC_SELECT, 0x7F, &spi_read_dat);
    spi_read_dat &= 0xFF;
    if (spi_read_dat != FMC120_DAC_PART_ID) {
        print_str("DAC ID doesn't match 0x0A:\n");
        print_hex(spi_read_dat, 2);
        print_str("\n");
        return false;
    } else {
        print_str("DAC VendorID:  ");
        print_hex(spi_read_dat >> 3, 2);
        print_str("\n");
        print_str("DAC Version:   ");
        print_hex(spi_read_dat & 0x3, 2);
        print_str("\n");
    }

    // Make sure jesd init_state=1111
    // ret &= FMC120_SPI_Write(DAC_SELECT, 0x4A, 0xFF1E);

    uint8_t clkjesd_div;
    uint8_t interp;
    bool pll_sleep, pll_reset, pll_ena;
    uint8_t pll_p, pll_m;
    uint8_t serdes_clk_sel, serdes_refclk_div;
    uint8_t mode = 0;
    switch (mode) {
        case 0:  // use LMK Clock directly, interp = 1
            clkjesd_div = 1;        // interp * L / M = 2
            interp = 0;             // 1x
            pll_sleep = 1;
            pll_reset = 1;
            pll_ena = 0;
            pll_p = 0;
            pll_m = 0;
            serdes_clk_sel = 0;     // !!! has to be 0 to use DAC CLK !!!
            serdes_refclk_div = 1;  // REF 1GHz, div2=500MHz
            break;

        case 1:  // use DAC PLL 1GHz in 1GHz out, interp = 1
            clkjesd_div = 1;        // div2 jesd pll reference = DACCLK/2
            interp = 0;             // 1x
            pll_sleep = 0;
            pll_reset = 0;
            pll_ena = 1;
            pll_p = 2;              // P = 4
            pll_m = 1;              // M = 2
            serdes_clk_sel = 1;     // use LMK clock directly
            serdes_refclk_div = 1;  // REF 1GHz, div2=500MHz
        break;

        default:  // use DAC PLL 1GHz in 2GHz out, interpolate by 2
            // JESD Clock divider = Lanes * Interpolation / 4 DACS = 0x4000
            clkjesd_div = 2;        // div4 (8L * interp2 = 16)/4 jesd pll reference = DACCLK//4
            interp = 1;             // 2x
            pll_sleep = 0;
            pll_reset = 0;
            pll_ena = 1;
            pll_p = 0;              // P = 2
            pll_m = 3;              // M = 4
            serdes_clk_sel = 1;     // use LMK clock directly
            serdes_refclk_div = 3;  // REF 1GHz, div4=250MHz
    }

    // JESD settings
    uint8_t pL = 8;         // Number of lanes
    uint8_t pM = 4;         // Number of converters per link
    uint8_t pF = 1;         // Number of octest per frame per lane
    uint8_t pS = 1;         // Number of converter samples per frame
    uint8_t pK = 32;        // Number of frames per multiframe
    uint8_t pHD = 1;        // High Density
    uint8_t pN = 16;        // Number of bits per sample
    uint8_t pN_prime = 16;  // Number of adjusted bits per sample

    // Valid 4 - 32
    uint8_t rbd = 8;

    // app note SLAA696, section 7.5
    t_reg16 regmap[] = {
        { 0x1A, (pll_sleep<<6)},    // config26: pll_sleep
        { 0x25, (clkjesd_div<<13)}, // config37: clkjesd_div

        // SLAA696 Step 4.a
        { 0x31, 0x6808 | (pll_reset<<12) | (pll_ena<<10) },
                                    // config49: pll_reset, pll_ena, pll_ndivsync_ena=1,pll_n=1
        { 0x32, (pll_m<<8) | (pll_p<<4) },      // config50: PLL_M, PLL_P
        { 0x33, 0xAF40 },           // config51: pll_vcosel, pll_vco, pll_vcoitune, pll_cp_adj
        { 0x34, 0x0080 },           // config52: syncb_lvds_sub_ena=1 for 0.9V vcm

        // SLAA696 Step 4.b
        { 0x3B, (serdes_clk_sel<<15) | (serdes_refclk_div<<11) },
                                    // config59: serdes_clk_sel, serdes_refclk_div
        { 0x3C, 0x0228 },           // config60: Full Rate, 4 samples per serdes cycle
                                        // PLL out freq=2.5GHz. Serdes PLL refclk= 2.5G/5=500MHz
                                        // [8:1] MPY=0b10100, factor=5
        { 0x3D, 0x0088 },           // config61: rw_cfgrx0 msb
        { 0x3E, 0x0108 },           // config62: rw_cfgrx0 lsb
                                        // [15:13] LOS=0, [10:8] TERM=001, [6:5]RATE=Full, [4:2]BusWidth=010 (20bit)
        { 0x3F, 0x0000},            // config63: 0x0000 DP0_P/N normal    0x00FF DP0_P/N Inverted (Swapped)

        // SLAA696 Step 4.c
        { 0x46, 0x0044 },           // config70: lid0=0, lid1=1, lid2=2
        { 0x47, 0x190A },           // config71: lid3=3, lid4=4, lid5=5
        { 0x48, 0x31c3 },           // config72: lid6=6, lid7=7, subclassv=1, jesdv=1
        { 0x49, 0x0000 },           // config73: assign to link0
        { 0x4A, 0xFF1E },           // config74: lane_ena=0xFF, init_state=1111, reset jesd
        { 0x4B, ((rbd-1)<<8) | (pF-1) },                // config75: RBD<=K, F = 1
        { 0x4C, ((pK-1)<<8)  | (pL-1) },                // config76: K = 32 L = 8
        { 0x4D, ((pM-1)<<8)  | (pS-1) },                // config77: M = 4 S = 1
        { 0x4E, ((pN_prime-1)<<8) | (pHD<<6) | (pN-1) },// SCR=0, HD=1, N'=16, N=16
        { 0x4F, 0x1CC1 },           // config79:
        { 0x50, 0x0000 },           // config80: adjcnt_link0, adjdir_link0, bid_link0, cf_link0, cs_link0
        { 0x51, 0x00DF },           // config81: Disable link-conf err, XXX why?
        { 0x52, 0x00FF },           // config82: error_ena_link0=0xff
        { 0x53, 0x0000 },           // config83: adjcnt_link1, adjdir_link1, bid_link1, cf_link1, cs_link1
        { 0x54, 0x0000 },           // config84: sync_request_ena_link1=0x00
        { 0x55, 0x0000 },           // config85: error_ena_link1=0x00
        { 0x5F, 0x0123 },           // config95: lane mapping
        { 0x60, 0x4567 },           // config96: lane mapping
        { 0x61, 0x0001 },           // config97: syncn_sel=0x1, SYNCB ONLY USE LINK0

        // SLAA696 Step 4.d
        { 0x00, (interp<<8) | 0x18},// config0 : interp, alarm_out_ena=1, alarm_out_pol=1
        { 0x02, 0x2082 },           // config2 : zero_invalid_data=1, sif4_ena=1, twos=1
        { 0x03, 0xA300 },           // config3 : DAC coarse current adjust , set to 20mA,
        { 0x1E, 0x4444 },           // config30: syncsel_qmoffsetab/cd, syncsel_qmcorrab/cd
        { 0x1F, 0x4440 },           // config31: syncsel_mixerab, syncsel_mixercd, syncsel_nco
        { 0x20, 0x4044 },           // config32

        { 0x01, 0x0050 },           // complement DAC outputs Ch1 and Ch3
        { 0x04, 0x0000 },           // Enable alarms for lane errors and fifo flags
        { 0x05, 0xE002 },           // Enable alarms for sysref
        { 0x06, 0xFFFF },           // Enable alarms for shorttest, los
        { 0x6C, 0x0000 },           // config108: clear sysref errors

        // SLAA696 Step 5, check later
        // SLAA696 Step 6, done in 4.c
        // SLAA696 Step 7-13, no retry
        { 0x05, 0xE002 },           // SLAA696 step 7. alarm_sysref_err active
        { 0x24, 0x0030 },           // SLAA696 step 8. cdrvser_sysref_mode=011. use 2nd pulse.
        { 0x5C, 0x000D },           // SLAA696 step 9. sysref_mode_link0 use 3rd pulse.
                                    // err_cnt_clk_link0 = 1
        { 0x4A, 0xFF1F },           // SLAA696 step 11. Initialize JESD block
        { 0x4A, 0xFF01 },           // SLAA696 step 12. Initialize JESD block
    };

    ret &= FMC120_SPI_WriteRegs(DAC_SELECT, regmap, sizeof(regmap)/sizeof(regmap[0]));

    // uint16_t pll_mask = pll_ena ? 0xFFFF : 0xFFFE;
    // 12. Verify SERDES PLL lock status
    // SLAA696 step 5. Check alarm_from_pll, alarm_rw0_pll, alarm_rw1_pll
    // print_str("  DAC PLL               : ");
    // ret &= FMC120_SPI_Read(DAC_SELECT, 0x6C, &spi_read_dat);
    // FMC120_PrintStatus((spi_read_dat & pll_mask) == 0x2);

    // SLAA696 step 14. gapped periodic SYSREF, SYNCB should be low
    FMC120_LMK04828_SyncAll();

    // 16. Clear alarms, check lane and link err cnts
    // ret &= FMC120_check_dac_alarms(pll_ena);

    print_str(" --- FMC120 DAC Init ---: ");
    FMC120_PrintStatus(ret);
    return ret;
}

bool FMC120_check_dac_alarms(bool pll_ena) {
    bool valid=true;
    bool alarm_valid=true;
    uint16_t spi_read_dat;
    uint16_t pll_mask = pll_ena ? 0xFFFF : 0xFFFE;

    t_reg16 regmap1[] = {
        { 0x64, 0x0 },    //lane 0
        { 0x65, 0x0 },    //lane 1
        { 0x66, 0x0 },    //lane 2
        { 0x67, 0x0 },    //lane 3
        { 0x68, 0x0 },    //lane 4
        { 0x69, 0x0 },    //lane 5
        { 0x6A, 0x0 },    //lane 6
        { 0x6B, 0x0 },    //lane 7
        { 0x6C, 0x0 },    //
        { 0x6D, 0x0 },    // lane alarm LOS alarm
    };
    FMC120_SPI_WriteRegs(DAC_SELECT, regmap1, sizeof(regmap1)/sizeof(regmap1[0]));

    print_str("    DAC PLL             : ");
    FMC120_SPI_Read(DAC_SELECT, 0x6C, &spi_read_dat);
    valid &= (spi_read_dat & pll_mask) == 0x2;
    FMC120_PrintStatus(valid);
    if (!valid) {
        // Unacceptable alarm_sysref_err, pll_alarm, serdes_alarm
        print_str("DBG 0x6C :");
        print_hex(spi_read_dat, 4);
        print_str("\n");
        return false;
    }

    if (pll_ena) {
        print_str("    PLL Filter Volt     : ");
        FMC120_SPI_Read(DAC_SELECT, 0x31, &spi_read_dat);
        spi_read_dat &= 0x7;
        FMC120_PrintStatus(spi_read_dat == 3 || spi_read_dat == 4);
    }

    print_str("    DAC LANE LOS        : ");
    FMC120_SPI_Read(DAC_SELECT, 0x6D, &spi_read_dat);
    valid &= spi_read_dat == 0;
    FMC120_PrintStatus(valid);

    uint8_t ix;
    print_str("    DAC LANE: ");
    for (ix=0; ix<8; ix++) {
        FMC120_SPI_Read(DAC_SELECT, 0x64+ix, &spi_read_dat);
        alarm_valid = ((spi_read_dat & ~0x3) == 0 );       // ignore read alarms of 'FIFO is empty'
        print_str( alarm_valid ? " OK" :  "FAIL");
        if (!alarm_valid) {
            print_str("\n DBG 0x");
            print_hex(ix + 0x64, 2);
            print_str(" : ");
            print_hex(spi_read_dat, 4);
        }
        valid &= alarm_valid;
    }
    print_str("\n    DAC LINK: ");
    for (ix=0; ix<4; ix++) {
        FMC120_SPI_Read(DAC_SELECT, 0x41+ix, &spi_read_dat);
        alarm_valid = (spi_read_dat <= 2);  // XXX
        valid &= alarm_valid;
        print_str( alarm_valid ? " OK" :  "FAIL");
        if (!alarm_valid) {
            print_str("\n DBG 0x");
            print_hex(ix + 0x41, 2);
            print_str(" : ");
            print_hex(spi_read_dat, 4);
        }
    }
    print_str("\n");

    return valid;
}

bool FMC120_ADS54J60_Reset(void) {
    bool ret = true;
    uint8_t byteBuf;
    ret &= i2c_read_regs( I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);
    // force a clear on the ADC Reset Pins, ensures a low on abnormal terminations or restarts
    byteBuf &= 0xF9;
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);
    // Set reset bits active
    byteBuf |= 0x06;
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);
    // clear reset bits
    byteBuf &= 0xF9;
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL2, &byteBuf, 1);

    DELAY_MS(2);
    return ret;
}

bool FMC120_ResetADC(void) {
    t_reg16 regmap[] = {
        { 0x4005, 0x00 },       // enable broadcast
        { 0x4003, 0x00 },       // select JESD Digital Page
        { 0x4004, 0x68 },       // select JESD Digital Page
        { 0x60F7, 0x00 },       // Digital Reset
        { 0x6000, 0x01 },       // assert pulse Reset
        { 0x6000, 0x00 }        // clear pulse Reset
    };
    return FMC120_SPI_WriteRegs(ADC_SELECT_BOTH, regmap, sizeof(regmap)/sizeof(regmap[0]));
}

bool FMC120_InitADC(void) {
    bool ret = true;
    uint8_t byteBuf;
    ret &= FMC120_ADS54J60_Reset();

    // power up adc input amplifiers
    ret &= i2c_read_regs( I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL0, &byteBuf, 1);

    // clear ADCx_Amp_Off bits
    byteBuf &= 0xF3;
    ret &= i2c_write_regs(I2C_ADR_FMC120_CPLD, CPLD_ADR_CONTROL0, &byteBuf, 1);

    DELAY_MS(2);

    t_reg16 regmap[] = {
        { 0x0000, 0x81 },        // LMFS = 4211
        { 0x0011, 0x80 },        // select master page of analog bank
        // set analog input to DC coupling Z5K **********************************
        { 0x004F, 0x00 },        // DC coupling enable Bit 0 = off,  1 = Enabled shifts VCM at adc down ~ 200mV ***
        { 0x0026, 0x40 },        // IGNORE inputs on power down pin
        { 0x0059, 0x20 },        // Set the always write 1 Bit

        // select main digital page 6800
        { 0x4003, 0x00 },        // select JESD Digital Page
        { 0x4004, 0x68 },        // select JESD Digital Page
        { 0x6842, 0x00 },        // nyquist_zone=0:0-500MHz
        { 0x684E, 0x80 },

        { 0x4005, 0x01 },        // enable single channel writes
        { 0x4004, 0x68 },        // Upper byte of page address
        { 0x4003, 0x00 },        // middle byte
        { 0x4002, 0x00 },        // middle byte
        { 0x4001, 0x00 },        // lower byte of 32bit page address
        { 0x604E, 0x20 },        // for CH-A, write to register address 0x4E for a feature Update
        { 0x704E, 0x20 },        // for CH-B, write to register address 0x4E for a feature Update

        // select main digital page 6800, put the ADC select back where we found it
        { 0x4005, 0x00 },        // enable broadcast
        { 0x4003, 0x00 },        // select JESD Digital Page
        { 0x4004, 0x68 },        // select JESD Digital Page

        // *** DIGITAL CORE RESET ***
        // the digital reset must be pulsed for register writes to take effect
        { 0x60F7, 0x00 },        // Digital Reset
        { 0x6000, 0x01 },        // assert pulse Reset
        { 0x6000, 0x00 },        // clear pulse Reset

        // select 6A00 JESD Anlaog Page
        { 0x4003, 0x00 },        // select JESD Digital Page
        { 0x4004, 0x6A },        // select JESD Digital Page
        { 0x6016, 0x02 },        // 40X pll

        // select 6900 Digital JESD Page
        { 0x4003, 0x00 },        // select page lowbyte
        { 0x4004, 0x69 },        // select page highbyte
        { 0x6001, 0x04 },        // set LMF = 4211
        { 0x6007, 0x08 },        // set internal defaults JESDV and subclass V1
        { 0x6000, 0x80 },        // set control K
        { 0x6006, 0x1F },        // set K to 32

        { 0x4005, 0x00 },       // enable broadcast
        { 0x4003, 0x00 },       // select JESD digital Page
        { 0x4004, 0x68 }        // select JESD digital Page
    };

    ret &= FMC120_SPI_WriteRegs(ADC_SELECT_BOTH, regmap, sizeof(regmap)/sizeof(regmap[0]));
    print_str(" --- FMC120 ADC Init ---: ");
    FMC120_PrintStatus(ret);
    return ret;
}

void FMC120_write_axi_regmap(uint32_t base_core, const t_reg32 *regmap, size_t len) {
    while ( len-- > 0 ){
        write_jesd204_axi(base_core, regmap->addr, regmap->data);
        regmap++;
    }
}

void reset_jesd204_core(uint32_t base_core) {
    uint32_t dword = 1;
    write_jesd204_axi(base_core, 0x04, 0x01); // Reset core

    print_str("    Core Reset wait");
    while (dword != 0) {
        dword = read_jesd204_axi(base_core, 0x04);
        print_str(".");
    }
    print_str(" Done.\n");
}

bool init_jesd204_core(void) {
    bool pass = true;

    uint32_t sysref_required = 0;    // 0: No sysref required on re-sync.
    uint32_t sysref_delay = 3;       // 0-15
    uint32_t sysref_always = 1;      // 1: All sysref event will reset LMFC counter
    uint32_t rx_buf_delay = 1;      // read buffer ajdust @ 0x830

    const t_reg32 jesd_cfg_adc[] = {
        { 0x08, 0x01 },         // 0x08: Support ILA
        { 0x0c, 0x00 },         // 0x0C: Scrambling disabled
        { 0x10, (sysref_required << 16) | (sysref_delay << 8) | sysref_always},
                                // 0x10: SYSREF once for re-sync
        { 0x18, 0x00 },         // 0x18: Test Modes: normal operation
        { 0x20, 0x00 },         // 0x20: F=1
        // { 0x24, 0x07 },         // 0x24: K = 8
        { 0x24, 0x1f },         // 0x24: K = 32
        { 0x28, 0x0f },         // 0x28: L = 4
        { 0x2c, 0x01 },         // 0x2c: subclass = 1
        { 0x30, rx_buf_delay },         // 0x30: Rx buffer delay
        { 0x34, 0x01 }          // 0x34: Rx error reporting
    };

    sysref_required = 0;
    sysref_delay = 3;
    const t_reg32 jesd_cfg_dac[] = {
        { 0x08, 0x01 },         // 0x08: Support ILA
        { 0x0c, 0x00 },         // 0x0C: Scrambling disabled
        { 0x10, (sysref_required << 16) | (sysref_delay << 8) | sysref_always},
        { 0x14, 0x03 },         // ILA multiframes = 4
        { 0x18, 0x00 },         // 0x18: Test Modes: normal operation
        { 0x20, 0x00 },         // 0x20: F = 1
        { 0x24, 0x1f },         // 0x24: K = 32
        { 0x28, 0xff },         // 0x28: L = 8
        { 0x2c, 0x01 },         // 0x2c: subclass = 1
        { 0x30, 0x00 },         // 0x30: Rx buffer delay
        { 0x34, 0x01 },         // 0x34: Rx error reporting
        {0x80C, 0x00000000 },   // ILA Config Data 3: [11:8]: BID, [7:0]: DID
        {0x810, 0x000F0F03 },   // ILA Config Data 4: [25:24]: CS, [20:26]: N', [12:8]: N, [7:0]: M
        {0x814, 0x80000000 },   // ILA Config Data 5: [16]: HD, [12:8]: S, [0]:SCR
    };

    uint32_t bases[] = {
        BASE2_JESD_ADC0,
        BASE2_JESD_ADC1,
        BASE2_JESD_DAC
    };

    uint32_t base_core;
    uint32_t dword;
    const t_reg32 *jesd_cfg = jesd_cfg_adc;
    size_t size_cfg_adc = sizeof(jesd_cfg_adc)/sizeof(jesd_cfg_adc[0]);
    size_t size_cfg_dac = sizeof(jesd_cfg_dac)/sizeof(jesd_cfg_dac[0]);

    print_str("JESD204 Core Init:\n");
    for (size_t i=0; i<3; i++) {
        // Check core versions to be 7.2.x
        // 7.2.1 (vivado 2017.4)
        // 7.2.6 (vivado 2019.1)
        base_core = bases[i];
        dword = read_jesd204_axi(base_core, 0); // 0x00: Read Version
        pass &= (dword>>16 == 0x0702);
        if (!pass) {
            print_str("JESD204 Core Version:\n");
            print_hex(dword, 8);
        }

        jesd_cfg = (base_core == BASE2_JESD_DAC) ? jesd_cfg_dac : jesd_cfg_adc;
        FMC120_write_axi_regmap(
            base_core, jesd_cfg, (base_core == BASE2_JESD_DAC) ? size_cfg_dac : size_cfg_adc
        );

        reset_jesd204_core(base_core);
    }
    return pass;
}

bool check_jesd204_sync(uint32_t base_core) {
    uint32_t dword;
    bool pass;
    dword = read_jesd204_axi(base_core, 0x38);
    pass = (dword & 0x01);
    print_str("JESD Sync Status: ");
    FMC120_PrintStatus(pass);
    return pass;
}

void FMC120_LMK04828_SyncAll(void) {
    // Follow datasheet example:
    // Toggle SYNC pin, which applies to both boards simutanously
    // LMK04828 Table 2, Differential input SYNC (SYNC_MODE = 1, SYSREF_MUX = 0)
    SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, PIN_LMK_SYNC, 1 );
    SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, PIN_LMK_SYNC, 0 );
}

void FMC120_print_dac_core_status(void) {
    uint32_t dword;
    bool status[2];
    for (size_t j=0; j<15; j++) {
        dword = read_jesd204_axi(BASE2_JESD_DAC, (j<<2));
        print_str("JESD DAC Adr ");
        print_hex((j<<2), 4);
        print_str(":");
        print_hex(dword, 8);
        print_str("\n");
    }
    for (size_t j=256; j<256+8; j++) {
        dword = read_jesd204_axi(BASE2_JESD_DAC, (j<<2));
        print_str("JESD DAC LANE ");
        print_hex(j-256, 4);
        print_str(" ID :");
        print_hex(dword, 8);
        print_str("\n");
    }
    for (size_t j=512+3; j<512+8; j++) {
        dword = read_jesd204_axi(BASE2_JESD_DAC, (j<<2));
        print_str("JESD ILA CFG ");
        print_hex(j-512, 4);
        print_str(" DAT :");
        print_hex(dword, 8);
        print_str("\n");
    }
    status[0] = check_jesd204_sync(BASE2_JESD_DAC);
    print_str(status[0] ? "Pass\n" : "Fail\n");
    dword = GET_REG(g_base_jesd_sfr);
    print_str("JESD SFR:");
    print_hex(dword, 8);
    print_str("\n");
    dword = GET_REG(g_base_sfr);
    print_str("BASE SFR:");
    print_hex(dword, 8);
    print_str("\n");
}

void FMC120_print_adc_core_status(void) {
    uint32_t dword;
    bool status[2];
    status[0] = check_jesd204_sync(BASE2_JESD_ADC0);
    status[1] = check_jesd204_sync(BASE2_JESD_ADC1);
    print_str(status[0] ? "Pass\n" : "Fail\n");
    print_str(status[1] ? "Pass\n" : "Fail\n");

    dword = GET_REG(g_base_jesd_sfr);
    print_str("JESD SFR:");
    print_hex(dword, 8);
    print_str("\n");
    dword = GET_REG(g_base_sfr);
    print_str("BASE SFR:");
    print_hex(dword, 8);
    print_str("\n");

    for (uint8_t j=0; j<15; j++) {
        print_str("JESD ADC  Adr ");
        dword = read_jesd204_axi(BASE2_JESD_ADC0, (j<<2));
        print_hex((j<<2), 4);
        print_str(":");
        print_hex(dword, 8);
        // print_str("\n");
        print_str("    ");
        dword = read_jesd204_axi(BASE2_JESD_ADC1, (j<<2));
        // print_str("JESD ADC1 Adr ");
        // print_hex((j<<2), 4);
        //print_str(":");
        print_hex(dword, 8);
        print_str("\n");
    }
    for (size_t j=512+3; j<512+8; j++) {
        dword = read_jesd204_axi(BASE2_JESD_ADC0, (j<<2));
        print_str("JESD ILA CFG ");
        print_hex(j-512, 4);
        print_str(" DAT :");
        print_hex(dword, 8);
        print_str("    ");
        dword = read_jesd204_axi(BASE2_JESD_ADC1, (j<<2));
        print_hex(dword, 8);
        print_str("\n");
    }
    print_str("    ADC0 debug status:");
    dword = read_jesd204_axi(BASE2_JESD_ADC0, 0x3C);
    print_hex(dword, 8);
    print_str("\n");

    print_str("    ADC0 buffer adjust:");
    dword = read_jesd204_axi(BASE2_JESD_ADC0, 0x830);
    print_hex(dword, 8);
    print_str("\n");

    print_str("    ADC1 debug status:");
    dword = read_jesd204_axi(BASE2_JESD_ADC1, 0x3C);
    print_hex(dword, 8);
    print_str("\n");

    print_str("    ADC0 buffer adjust:");
    dword = read_jesd204_axi(BASE2_JESD_ADC1, 0x830);
    print_hex(dword, 8);
    print_str("\n");
}
