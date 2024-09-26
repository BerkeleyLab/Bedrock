#include "zest.h"

t_reg32 regmap_lmk01801[] = {
    // uWireLock        ="0"
    // hex(0b101111_0)
    { 0xf, 0x5eUL },  // UnLock
    // RESET            ="1",
    { 0x0, 0x1UL },
    // CLKin1_MUX       ="01",
    // CLKin1_DIV       ="000",
    // CLKin0_MUX       ="01"
    // CLKin0_DIV       ="100",   # 500*11/12 / 4 @ 114.6MHz
    // RESET            ="0",
    // hex(0b01001000_01_000_01_100_11_00000000)
    { 0x0, 0x4843300UL },
    // CLKout7_TYPE     ="0000",  # Powerdown
    // CLKout6_TYPE     ="0001",  # LVDS J12 U.FL
    // CLKout4_TYPE     ="0001",  # LVDS TO_FPGA
    // CLKout5_TYPE     ="0001",  # LVDS DAC
    // CLKout3_TYPE     ="000",   # Powerdown  TO_FPGA
    // CLKout2_TYPE     ="001",   # LVCMOS J13 U.FL
    // CLKout1_TYPE     ="001",   # LVDS  ADC2
    // CLKout0_TYPE     ="001"    # LVDS  ADC1
    // hex(0b0000_0001_0001_0001_000_001_001_001)
    { 0x1, 0x0111049UL },
    // CLKout13_TYPE    ="0000",  # Powerdown
    // CLKout12_TYPE    ="0000",  # Powerdown
    // CLKout11_TYPE    ="0110",  # CMOS J24 U.FL
    // CLKout10_TYPE    ="0001",  # LVDS J20 SMA
    // CLKout9_TYPE     ="0000",  # Powerdown
    // CLKout8_TYPE     ="0000"   # Powerdown
    // hex(0b0000_0000_0000_0110_0001_0000_0000)
    { 0x2, 0x6100UL },
    // SYNC1_AUTO       ="0",     # SYNC by R4/R5
    // SYNC0_AUTO       ="1",     # SYNC by R5
    // SYNC1_FAST       ="1",
    // SYNC0_FAST       ="1",
    // SYNC0_POL_INV    ="0",     # SYNC active high
    // SYNC1_POL_INV    ="0",     # SYNC active high
    // SYNC1_QUAL       ="0"
    // hex(0b00010_0011_011_0000_00_0_00_0_000000)
    { 0x3, 0x11b0000UL },
    // CLKout12_13_DDLY ="0000000000"
    { 0x4, 0x0UL },
    // CLKout12_13_DIV  ="00000000001",
    // CLKout8_11_DIV   ="001",  # J20, J24         @ 114.6MHz
    // CLKout4_7_DIV    ="001",  # FPGA, DAC, J12,  @ 114.6MHz
    // CLKout0_3_DIV    ="001"   # ADC1/2, J13      @ 114.6MHz
    // hex(0b0000_00000000001_00_0_0_001_001_001)
    { 0x5, 0x2049UL },
    // uWireLock =      ="1"
    // hex(0b101111_1)
    { 0xf, 0x5fUL }  // Lock
};

t_reg32 regmap_ad9653[] = {
    {0x000, 0x18 }, // MSB1st, Soft reset, 16-bit
    // { 0x008, 0x03 }, // reset
    {0x008, 0x00 }, // chip run
    {0x009, 0x01 }, // duty cycle stabilizer on
    {0x100, 0x46 }, // sample rate override
    // {0x0ff, 0x01 }, // init sample rate override
    {0x014, 0x07 }, // format=two's comp, invert
    {0x018, 0x00 }, // internal verf 1.0 Vpp
    {0x021, 0x30 }  // DDR two-lane, bytewise
    // {0x021, 0x20 }  // DDR two-lane, bitwise
};

t_reg32 regmap_ad9781[] = {
    {0x00, 0x00},    // reset
    {0x02, 0x00},
    {0x03, 0x00},
    {0x04, 0x00},
    {0x05, 0x0c},    // measured SMP
    {0x0a, 0x05},    // mix mode
    // {0x0b, 0xff},    // DAC1 FSC, Ifs = 31.66mA
    // {0x0c, 0x03},    // DAC1 FSC, Ifs = 31.66mA
    // {0x0f, 0xff},    // DAC2 FSC, Ifs = 31.66mA
    // {0x10, 0x03}     // DAC2 FSC, Ifs = 31.66mA
};

t_reg32 regmap_ad7794[] = {
    {0x1, 0x200a},   // mode: single conversion, t_settle=120ms
    {0x2, 0x0090}    // configuration, range 2.5V, internal ref
};

t_reg32 regmap_amc7823[] = {
    // addr = {PG[1:0], 1'b0, ADR[4:0]}
    // { (1<<6) | 0xc, 0xbb30}, // # AMC7823 RESET register, invoke system reset
    { (1<<6) | 0xb, 0x8080}, // # ADC
    { (1<<6) | 0xd, 0x8010}, // # PWR Down: only enable ADC and PREFB
};

#ifndef DSP_FREQ_MHZ
    #define DSP_FREQ_MHZ 117.29
#endif
#define FCNT_EXP DSP_FREQ_MHZ * (1<<16) / 125

// ADC0_DIV, ADC1_DIV, DAC_DCO, DSP_CLK
uint16_t fcnt_exp[4] = {
    FCNT_EXP,
    FCNT_EXP,
    FCNT_EXP * 2,
    FCNT_EXP
};

// ADC0_DIV, ADC1_DIV, DAC_DCO
int8_t phs_center[] = {
    70, 64, 64
};

uint8_t ad9781_smp[] = {
    12, 12, 12
};

const zest_init_t zest_init_data = {
    {
        sizeof(regmap_lmk01801) / sizeof(regmap_lmk01801[0]),
        regmap_lmk01801
    },
    {
        sizeof(regmap_ad9653) / sizeof(regmap_ad9653[0]),
        regmap_ad9653
    },
    {
        sizeof(regmap_ad9781) / sizeof(regmap_ad9781[0]),
        regmap_ad9781
    },
    {
        sizeof(regmap_ad7794) / sizeof(regmap_ad7794[0]),
        regmap_ad7794
    },
    {
        sizeof(regmap_amc7823) / sizeof(regmap_amc7823[0]),
        regmap_amc7823
    },
    fcnt_exp,
    phs_center,
    ad9781_smp
};
