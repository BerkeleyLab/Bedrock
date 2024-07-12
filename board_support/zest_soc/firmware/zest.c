#include <stdint.h>
#include <stdbool.h>
#include "settings.h"
#include "zest.h"
#include "gpio.h"
#include "timer.h"
#include "spi.h"
#include "common.h"
#include "iserdes.h"
#include "sfr.h"
#include "wfm.h"
#include "awg.h"
#include "print.h"
#ifdef NONSTD_PRINTF
    #include "printf.h"
#else
    #include <stdio.h>
#endif

uint32_t g_base_adc; //  = BASE_ZEST + ZEST_BASE2_ADC;
uint32_t g_base_sfr; //  = BASE_ZEST + ZEST_BASE2_SFR;
uint32_t g_base_spi; //  = BASE_ZEST + ZEST_BASE2_SPI;
uint32_t g_base_wfm; //  = BASE_ZEST + ZEST_BASE2_WFM;
uint32_t g_base_awg; //  = BASE_ZEST + ZEST_BASE2_AWG;

static zest_devinfo_t g_devinfo = {ZEST_DEV_ILLEGAL, 0, 0, 0, 0};

const char *zest_fcnt_names[] = {
    "ADC0_DIV", "ADC1_DIV", "DAC_DCO", "DSP_CLK"
};
const char *zest_phdiff_names[] = {
    "ADC0_DIV", "ADC1_DIV", "DAC_DCO"
};

const uint8_t g_zest_adcs[] = {
    ZEST_DEV_AD9653A,
    ZEST_DEV_AD9653B
};

bool get_spi_ready(void) {
    return !CHECK_BIT(SPI_GET_STATUS(g_base_spi), BIT_CIPO);
}

uint32_t wait_ad7794_spi_ready(void) {
    uint32_t count=0;
    while (!get_spi_ready()) {
        if (++count > 600000 ) {
            printf("spi ready wait expired.\n");
            break;
        }
    }
    debug_printf("    wait_ad7794_spi_ready: %u \n", count);
    return count;
}

uint32_t read_zest_fcnt(zest_freq_t ch) {
    SET_REG8(g_base_sfr + SFR_OUT_BYTE_FCLK_SEL, (ch & 0x3));
    return GET_REG(g_base_sfr + (SFR_IN_REG_FCNT<<2));
}

int16_t read_clk_div_ph(zest_freq_t ch) {
    uint16_t reg_val;
    SET_REG8(g_base_sfr + SFR_OUT_BYTE_PH_SEL, (ch & 0x3));
    reg_val = GET_REG16(g_base_sfr + (SFR_IN_REG_PCNT<<2));
    return (int16_t)(reg_val << (16 - PH_DIFF_DW));
}

uint16_t read_adc_waveform_sample(uint8_t ch) {
    select_waveform_chan(g_base_wfm, ch);
    trigger_waveform(g_base_wfm);
    return read_waveform_addr(g_base_wfm, 0);
}

uint16_t read_zest_adc(uint8_t ch) {
    return read_adc_waveform_sample(ch);
}

void read_adc_waveform(uint16_t *buf, size_t len) {
    for (size_t ix=0; ix<len; ix++) {
        buf[ix] = read_waveform_addr(g_base_wfm, ix);
    }
}

void gen_prbs9(uint16_t *buf, size_t len) {
    // uint16_t start = 0x1ff; // step 0
    // uint16_t p = 0;         // step 0
    // pn9.c: XXX Step=1505, 16bit: 0xce17, state: 0x016c
    uint16_t p = 0xce17;
    uint16_t start = 0x016c;
    uint16_t sr = start;
    for (size_t ix = 1; ix <= len*16; ix++) {
        p = ((p << 1) | ((sr>>8) & 1));
        if (ix % 16 == 0) buf[ix/16-1] = p; // store result
        uint8_t newbit = (((sr >> 8) ^ (sr >> 4)) & 1);
        sr = ((sr << 1) | newbit) & 0x1ff;
    }
}

void reset_ad9781(void) {
    SET_SFR1(g_base_sfr, SFR_OUT_REG0, SFR_OUT_BIT_DAC_RESET, 1);
    SET_SFR1(g_base_sfr, SFR_OUT_REG0, SFR_OUT_BIT_DAC_RESET, 0);
}

void set_ad9781_smp(uint8_t dly) {
    write_zest_reg(ZEST_DEV_AD9781, 0x05, dly);
}

void set_ad9781_set_hld(uint8_t set, uint8_t hld) {
    write_zest_reg(ZEST_DEV_AD9781, 0x04, (set<<4) | hld);
}

bool get_ad9781_seek(void) {
    return read_zest_reg(ZEST_DEV_AD9781, 0x06) & 1;
}

bool align_ad9781(uint8_t* exp_smp) {
    // datasheet page 26, allows multiple expected smp values
    bool seek, seek_pre=0;
    uint8_t smp=0, smp_min=0;
    int diff, diff_min=32;
    printf("  %s: AD9781 Alignment:\n", __func__);
    for (smp=0; smp<32; smp++) {
        uint8_t v_set = 15;
        uint8_t v_hld = 15;
        set_ad9781_smp(smp);
        debug_printf(" SMP%3d HLD: ", smp);
        for (uint8_t hld=0; hld<16; hld++) {
            set_ad9781_set_hld(0, hld);
            seek = get_ad9781_seek();
            if (hld > 0 && (seek_pre ^ seek)) v_hld = hld;
            seek_pre = seek;
            debug_printf("%1d", seek);
        }
        debug_printf("%3d\n", v_hld);
        debug_printf("        SET: ");
        for (uint8_t set=0; set<16; set++) {
            set_ad9781_set_hld(set, 0);
            seek = get_ad9781_seek();
            if (set > 0 && (seek_pre ^ seek)) v_set = set;
            seek_pre = seek;
            debug_printf("%1d", seek);
        }
        debug_printf("%3d\n", v_set);
        diff = (v_hld > v_set) ? v_hld - v_set : 32;
        if (diff < diff_min) {
            diff_min = diff;
            smp_min = smp;
        }
    }
    printf("  %s: Found SMP value: %d.\n", __func__, smp_min);
    set_ad9781_smp(smp_min);
    // validate against expected values, allow +-160ps error bar
    for (uint8_t ix=0; ix<3; ix++) {
        diff = smp_min - exp_smp[ix];
        if (diff <= 1 && diff >= -1) {
            printf("  %s: SMP matches expected: %d.\n", __func__, exp_smp[ix]);
            return true;
        }
    }
    return false;
}

bool run_ad9781_bist(uint16_t bitres1_exp, uint16_t bitres2_exp) {
    uint8_t bytes[2];
    uint16_t bitres1, bitres2;
     // clear BIST register
    write_zest_reg(ZEST_DEV_AD9781, 0x1a, 0x20);
    write_zest_reg(ZEST_DEV_AD9781, 0x1a, 0x00);
    // enable BIST
    write_zest_reg(ZEST_DEV_AD9781, 0x1a, 0x80);
    // send known data series
    awg_trigger(g_base_awg);
    // perform BIST read
    write_zest_reg(ZEST_DEV_AD9781, 0x1a, 0xc0);
    // read rising edge sum
    bytes[0] = read_zest_reg(ZEST_DEV_AD9781, 0x1b);
    bytes[1] = read_zest_reg(ZEST_DEV_AD9781, 0x1c);
    bitres1 = bytes[1] << 8 | bytes[0];
    // read falling edge sum
    bytes[0] = read_zest_reg(ZEST_DEV_AD9781, 0x1d);
    bytes[1] = read_zest_reg(ZEST_DEV_AD9781, 0x1e);
    bitres2 = bytes[1] << 8 | bytes[0];
    printf("  %s: bitres: 0x%x, 0x%x\n", __func__, bitres1, bitres2);
    return (bitres1 == bitres1_exp) && (bitres2 == bitres2_exp);
}

bool check_ad9781_bist(void) {
    bool pass = true;
    // the "simple sum"
    // mentioned in the AD9781 data sheet is a misprint; actually some
    // undocumented but deterministic function, possibly LFSR-like.
    // References:
    // https://ez.analog.com/data_converters/high-speed_dacs/f/q-a/23105/ad9781-bist
    // https://github.com/analogdevicesinc/linux/blob/main/drivers/iio/frequency/ad9783.c#L371

    // uint16_t buf[] = {1,0};      // get 0xfffb
    // uint16_t buf[] = {2,0};      // get 0xfff7
    // uint16_t buf[] = {1,1};      // get 0x080c
    // uint16_t buf[] = {2,1};      // get 0x0814
    // uint16_t buf[] = {2,2};      // get 0x0818
    // uint16_t buf[] = {0x1000,0}; // get 0xbfff

    // Generate PRBS9 series
    // expect 0c7bb, given data samples:
    // b668 7787 fc1e f8b9 904a 768f 3e6c 548e
    // 36ae 2622 108 c272 ac37 a6e4 50ad 3f64
    // 96fc 9a99 80c6 51a5 fd16 3acb 3c7d d06b
    uint16_t bitres_exp = 0xc7bb;
    uint16_t buf[24];
    uint8_t len = sizeof(buf) / sizeof(uint16_t);
    gen_prbs9(buf, len);

    SET_REG16(g_base_awg + AWG_CFG_ADDR + AWG_CFG_BYTE_AWG_LEN, len);
    awg_write_dma(g_base_awg, buf, len);
    // optionally readback and check
    debug_printf("  %s: DAC awg samples (hex):\n", __func__);
    for (size_t addr=0; addr<len; addr++) {
        debug_printf(" %x", GET_REG(g_base_awg + (addr<<2)));
    }
    debug_printf("\n");

    // BIST only works in unsigned binary mode:
    // unsigned binary mode
    write_zest_reg(ZEST_DEV_AD9781, 0x2, 0x80);

    // select awg data source
    SET_SFR1(g_base_sfr, SFR_OUT_REG1, SFR_OUT_BIT_DAC0_SRCSEL, 1);
    SET_SFR1(g_base_sfr, SFR_OUT_REG1, SFR_OUT_BIT_DAC1_SRCSEL, 1);

    // test case 1: PRBS on dac0, zero on dac1
    SET_SFR1(g_base_sfr, SFR_OUT_REG1, SFR_OUT_BIT_DAC0_ENABLE, 1);
    SET_SFR1(g_base_sfr, SFR_OUT_REG1, SFR_OUT_BIT_DAC1_ENABLE, 0);
    pass &= run_ad9781_bist(bitres_exp, 0);

    // test case 2: PRBS on dac0, zero on dac1
    SET_SFR1(g_base_sfr, SFR_OUT_REG1, SFR_OUT_BIT_DAC0_ENABLE, 0);
    SET_SFR1(g_base_sfr, SFR_OUT_REG1, SFR_OUT_BIT_DAC1_ENABLE, 1);
    pass &= run_ad9781_bist(0, bitres_exp);

    // select dsp data source
    SET_SFR1(g_base_sfr, SFR_OUT_REG1, SFR_OUT_BIT_DAC0_SRCSEL, 0);
    SET_SFR1(g_base_sfr, SFR_OUT_REG1, SFR_OUT_BIT_DAC1_SRCSEL, 0);

    // two's complement binary mode
    write_zest_reg(ZEST_DEV_AD9781, 0x2, 0x0);
    return pass;
}

void reset_ad7794(void) {
    g_devinfo.dev = ZEST_DEV_ILLEGAL;
    SET_REG8(g_base_sfr + SFR_OUT_BYTE_CSB_SEL, ZEST_DEV_AD7794);
    SPI_INIT(g_base_spi, 1, 0, 1, 1, 0, 8, 16);
    for (size_t ix=0; ix<4; ix++) SPI_SET_DAT_BLOCK(g_base_spi, 0xff);
    wait_ad7794_spi_ready();
}

uint32_t read_ad7794_channel(uint8_t ch) {
    // internal ref, gain=0
    write_zest_reg(ZEST_DEV_AD7794, 2, (0x90 | (ch & 0x7)));
    // single conversion, Figure 21
    write_zest_reg(ZEST_DEV_AD7794, 1, 0x200a);
    SPI_INIT(g_base_spi, 1, 0, 1, 1, 0, 8, 16);
    SPI_SET_DAT_BLOCK(g_base_spi, 0x58);
    SPI_INIT(g_base_spi, 1, 0, 1, 1, 0, 24, 16);
    wait_ad7794_spi_ready();
    SPI_SET_DAT_BLOCK(g_base_spi, 0);
    return SPI_GET_DAT(g_base_spi) & 0xffffff;
}

void init_zest_spi(zest_dev_t dev) {
    uint8_t addr_len = 0;
    uint8_t data_len = 0;

    SET_REG8(g_base_sfr + SFR_OUT_BYTE_CSB_SEL, dev);
    switch (dev) {
        case ZEST_DEV_LMK01801:
            addr_len = 4;
            data_len = 28;
            // SCK cycles = 16, CPOL=0, CPHA=0, DW=32, MSB first
            SPI_INIT(g_base_spi, 0, 0, 0, 0, 0, 32, 16);
            break;
        case ZEST_DEV_AD9653A:
        case ZEST_DEV_AD9653B:
        case ZEST_DEV_AD9653_BOTH:
            addr_len = 13; // {R/WB, W1, W0, addr} = 16-bit inst, see AN-877
            data_len = 8;
            // SCK cycles = 16, CPOL=0, CPHA=0, DW=24, MSB first
            SPI_INIT(g_base_spi, 0, 0, 0, 0, 0, 24, 16);
            break;
        case ZEST_DEV_AD9781:
            addr_len = 5;
            data_len = 8;
            // SCK cycles = 16, CPOL=0, CPHA=0, DW=16, MSB first
            SPI_INIT(g_base_spi, 0, 0, 0, 0, 0, 16, 16);
            break;
        case ZEST_DEV_AD7794:
            // reset
            addr_len = 3;
            data_len = 16;
            // default for 24 bit registers
            // SCK cycles = 16, CPOL=1, CPHA=1, DW=24, MSB first
            SPI_INIT(g_base_spi, 0, 0, 1, 1, 0, 24, 16);
            break;
        case ZEST_DEV_AMC7823:
            // single register IO only, SADR==EADR
            addr_len = 8;       // {PG[1:0], 1'b0, ADR[4:0]}
            data_len = 16;
            // SCK cycles = 16, CPOL=0, CPHA=1, DW=32, MSB first
            SPI_INIT(g_base_spi, 0, 0, 0, 1, 0, 32, 16);
            break;
        default:
            g_devinfo.dev = ZEST_DEV_ILLEGAL;
            return;
    }
    g_devinfo.dev = dev;
    g_devinfo.addr_len = addr_len;
    g_devinfo.data_len = data_len;
    g_devinfo.addr_mask = (1 << addr_len) - 1;
    g_devinfo.data_mask = (1 << data_len) - 1;
}

void write_zest_reg(zest_dev_t dev, uint32_t addr, uint32_t val) {
    uint32_t inst=0;
    if (dev != g_devinfo.dev) {
        init_zest_spi(dev);
    }

    switch (dev) {
        case ZEST_DEV_LMK01801:
            inst = ((val & g_devinfo.data_mask) << g_devinfo.addr_len)
                + (addr & g_devinfo.addr_mask);
            break;
        case ZEST_DEV_AD9653A:
        case ZEST_DEV_AD9653B:
        case ZEST_DEV_AD9653_BOTH:
        case ZEST_DEV_AD9781:
            // R/WB = 0, [W1:W0] = 0: write 1 byte of data
            inst = ((addr & g_devinfo.addr_mask) << g_devinfo.data_len)
                + (val & g_devinfo.data_mask);
            break;
        case ZEST_DEV_AD7794:
            inst = (((addr & g_devinfo.addr_mask) << 3) << g_devinfo.data_len)
                + (val & g_devinfo.data_mask);
            break;
        case ZEST_DEV_AMC7823:
            inst = (((0<<15) | ((addr & g_devinfo.addr_mask)<<6) | (addr & 0x1f))
                    << g_devinfo.data_len)
                + (val & g_devinfo.data_mask);
            break;
        default:
            printf("write_zest_reg:  Invalid Device.\n");
            return;
    }
	SPI_SET_DAT_BLOCK( g_base_spi, inst );
}

uint32_t read_zest_reg(zest_dev_t dev, uint32_t addr) {
    uint32_t inst;

    if (dev != g_devinfo.dev) {
        init_zest_spi(dev);
    }

    switch (dev) {
        case ZEST_DEV_LMK01801:
            // Not supported
            printf("read_zest_reg:  LMK01801 reading not supported.\n");
            return 0;
        case ZEST_DEV_AD9653A:
        case ZEST_DEV_AD9653B:
        case ZEST_DEV_AD9781:
            // R/WB = 1, [W1:W0] = 0: read 1 byte of data
            inst = ((0x4 << g_devinfo.addr_len) | (addr & g_devinfo.addr_mask))
                    << g_devinfo.data_len;
            break;
        case ZEST_DEV_AD7794:
            inst = (((addr & g_devinfo.addr_mask) << 3) | 0x40)
                    << g_devinfo.data_len;
            break;
        case ZEST_DEV_AMC7823:
            inst = ((1<<15) | ((addr & g_devinfo.addr_mask)<<6) | (addr & 0x1f))
                    << g_devinfo.data_len;
            break;
        default:
            printf("read_zest_reg:  Invalid Device.\n");
            return 0;
    }
	SPI_SET_DAT_BLOCK( g_base_spi, inst );
	return SPI_GET_DAT( g_base_spi ) & g_devinfo.data_mask;
}

void write_zest_regs(zest_dev_t dev, const t_reg32 *regmap, size_t len) {
    while ( len-- > 0 ){
        write_zest_reg(dev, regmap->addr, regmap->data);
        regmap++;
    }
}

bool check_zest_regs(zest_dev_t dev, const zest_init_data_t *p_data) {
    bool pass = true;
    size_t len = p_data->len;
    t_reg32 *regmap = p_data->regmap;

    while ( len-- > 0 ){
        uint32_t temp = read_zest_reg(dev, regmap->addr);
        pass &= regmap->data == temp;
        debug_printf("SPI_Check: (%#06x, %#08x) %s\n",
                regmap->addr, temp, pass? "PASS": "FAIL");
        regmap++;
    }
    return pass;
}

bool check_zest_freq(zest_freq_t ch, uint32_t fcnt_exp) {
    uint32_t fcnt;
    DELAY_MS(2);

    fcnt = read_zest_fcnt(ch);
    printf("  Fclk %8s: ", zest_fcnt_names[ch]);
    print_udec_fix(fcnt*125, FCNT_WIDTH, 3);
    printf(" MHz\n");
    return (fcnt > fcnt_exp*0.98 && fcnt < fcnt_exp*1.02);
}

void sync_zest_clocks(void) {
    write_zest_reg(ZEST_DEV_LMK01801,  5, 0x2049UL);
    DELAY_MS(5);
}

void init_zest_clocks(zest_init_data_t *p_data) {
    write_zest_regs(ZEST_DEV_LMK01801, p_data->regmap, p_data->len);
    sync_zest_clocks();
    reset_zest_pll();
}

void reset_zest_bufr(uint8_t ch) {
    const uint8_t addr[] = {SFR_OUT_BIT_BUFR_A_RST, SFR_OUT_BIT_BUFR_B_RST};
    SET_SFR1(g_base_sfr, SFR_OUT_REG0, addr[ch], 1);
    SET_SFR1(g_base_sfr, SFR_OUT_REG0, addr[ch], 0);
}

void reset_zest_pll(void) {
    SET_SFR1(g_base_sfr, SFR_OUT_REG0, SFR_OUT_BIT_DSPCLK_RST, 1);
    DELAY_MS(5);
    SET_SFR1(g_base_sfr, SFR_OUT_REG0, SFR_OUT_BIT_DSPCLK_RST, 0);
    DELAY_MS(5);
}

bool check_zest_pll(void) {
    return GET_SFR1(g_base_sfr, 0, SFR_IN_BIT_DSPCLK_LOCKED);
}

bool check_div_clk_phase(uint8_t ch, int8_t center) {
    // dsp_clk and one of div_clk phase diff should be within small margin of
    // four edges   :  0.0,  0.25,  0.5, -0.25  UI (div_clk cycle, wrap)
    // cnt is 8 bit :    0,    64,  128,  -64 cnt
    // 0.25 edge is aligned, with +-0.125 margin
    int16_t ph_cnt;
    ph_cnt = read_clk_div_ph(ch) >> 8;
    printf("    Phase %8s clk: %6d  ", zest_phdiff_names[ch], ph_cnt);
    print_dec_fix(ph_cnt, 8, 3);
    printf(" UI.\n");
    ph_cnt -= center;
    return (ph_cnt > -32 && ph_cnt < 32);
}

bool align_dsp_clk_phase(int8_t center) {
    for (uint8_t ix=0; ix<16; ix++) {
        if (check_div_clk_phase(ZEST_FREQ_DAC_DCO, center)) {
            printf("  Phase DSP clk aligned. retry = %d.\n", ix);
            return true;
        } else{
            reset_zest_pll();
            DELAY_MS(3);
        }
    }
    printf(" dsp clk align failed.\n");
    return false;
}

bool align_adc_clk_phase(uint8_t ch, int8_t center) {
    for (uint8_t ix=0; ix<128; ix++) {
        if (check_div_clk_phase(ch, center)) {
            printf("  Phase %8s clk aligned. retry = %d.\n", zest_phdiff_names[ch], ix);
            return true;
        } else{
            reset_zest_bufr(ch);
            DELAY_MS(3);
        }
    }
    printf("  DIV %d clk align failed.\n", ch);
    return false;
}

bool init_zest_adcs(uint32_t base, int8_t bitslip_want) {
    bool pass = true;

    // Enable test pattern, single, mixed frequency
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xd, 0x0c);

    // IDELAY scan and ISERDES bitslip alignment process
    uint8_t idelay;
    int bitslips;
    // 1010 0001 1001 1100, AD9653 DS Table 13, when 0xD=00001100
    uint8_t test_pat[] = {0x9c, 0xa1};  // bytewise
    // uint8_t test_pat[] = {0x16, 0xca};   // bitwise

    for (uint8_t chan=0; chan < 2*4; chan++) {
        uint32_t ch_base = base + (chan << 16);
        printf("  ADC %d \n", chan);
        iserdes_reset(ch_base);

        for (uint8_t lane=0; lane<2; lane++) {
            iserdes_set_lane(ch_base, lane);
            // flip polarity due to hardware
            bitslips = iserdes_align_bits(ch_base, test_pat[lane]);
            idelay = iserdes_get_idelay(ch_base);
            printf("    idelay = %#4x, bitslipts = %d\n", idelay, bitslips);

            if (bitslip_want >= 0) {
                pass &= bitslips == bitslip_want;
            } else {
                pass &= bitslips >= 0;
            }
        }
    }
    // Alignment done. Disable test pattern
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xd, 0);
    return pass;
}

void select_zest_addr(uint32_t base) {
    g_base_adc = base + ZEST_BASE2_ADC;
    g_base_sfr = base + ZEST_BASE2_SFR;
    g_base_spi = base + ZEST_BASE2_SPI;
    g_base_wfm = base + ZEST_BASE2_WFM;
    g_base_awg = base + ZEST_BASE2_AWG;
}

void read_amc7823_adcs(void) {
    // AM7823 ADC, 12 bits:
    // ADC5: LO   = +2  dBm regx*2.5
    // ADC6: Curr = 0.7 A   regx*2.5
    // ADC7: Volt = 3.3/2 V   regx*2.5
    // ADC8: Temp = 25  C   regx*2.6*0.61 - 273
    uint16_t adc_vals[9];
    unsigned int ix;
    for (ix=0; ix<9; ix++) {
        adc_vals[ix] = read_zest_reg(ZEST_DEV_AMC7823, ix);
    }

    printf("ZEST AMC7823 ADC:\n");
    for (ix=0; ix<9; ix++) {
        printf("  ADC %u Val: %#06x", ix, adc_vals[ix]);
        if (ix == 8) {
            // printf(" Temp: %.3f [C]\n", (adc_vals[ix] & 0xfff) * 2.6 * 0.61 - 273);
            printf(" Temp:");
            print_dec_fix((adc_vals[ix] & 0xfff)*50 - 8736, 5, 3);
            printf("[C]\n");
        } else {
            // printf(" Volt: %.3f [V]\n", (adc_vals[ix] & 0xfff) * 2.5 / 0xfff);
            printf(" Volt:");
            print_dec_fix((adc_vals[ix] & 0xfff) * 2.5, 12, 3);
            printf("[V]\n");
        }
    }
}

void read_ad7794_adcs(void) {
    uint32_t adc_vals[6];
    unsigned int ix;
    printf("ZEST AD7794 ADC:\n");
    for (ix=0; ix<6; ix++) {
        adc_vals[ix] = read_ad7794_channel(ix);
        printf("  AIN %u: %#x", ix+1, adc_vals[ix]);
        printf(" Volt:");
        print_dec_fix((adc_vals[ix]) * 1.17, 24, 3); // internal 1.17V ref
        printf("[V]\n");
    }
}

void dump_zest_adc_regs(void) {
    uint32_t addrs[] = {
     0x000, 0x001, 0x002, 0x005, 0x008, 0x009, 0x00b, 0x00c,
     0x00d, 0x010, 0x014, 0x015, 0x016, 0x018, 0x019, 0x01a,
     0x01b, 0x01c, 0x021, 0x022, 0x100, 0x101, 0x102, 0x109};

    for (size_t ix=0; ix<2; ix++) {
        debug_printf("Dump ADC%d registers:\n", ix);
        for (size_t i=0; i<sizeof(addrs)/sizeof(addrs[0]); i++) {
            uint32_t temp = read_zest_reg(g_zest_adcs[ix], addrs[i]);
            debug_printf("  ADC Reg Dump: (%#06x, %#08x)\n", addrs[i], temp);
        }
    }
}

void dump_zest_dac_regs(void) {
    uint32_t addrs[] = {
        0x00, 0x02, 0x03, 0x04, 0x05, 0x06, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e,
        0x0f, 0x10, 0x11, 0x12, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f};

    debug_printf("Dump DAC registers:\n");
    for (size_t i=0; i<sizeof(addrs)/sizeof(addrs[0]); i++) {
        uint32_t temp = read_zest_reg(ZEST_DEV_AD9781, addrs[i]);
        debug_printf("  DAC Reg Dump: (%#04x, %#08x)\n", addrs[i], temp);
    }
}

bool init_zest(uint32_t base, zest_init_t *init_data) {
    bool pass=true;
    bool p=true;
    unsigned int ix;
    select_zest_addr(base);

    zest_init_data_t *p_lmk01801_data = &(init_data->lmk01801_data);
    zest_init_data_t *p_ad9653_data = &(init_data->ad9653_data);
    zest_init_data_t *p_ad9781_data = &(init_data->ad9781_data);
    zest_init_data_t *p_ad7794_data = &(init_data->ad7794_data);
    zest_init_data_t *p_amc7823_data = &(init_data->amc7823_data);
    uint32_t *fcnt_exp = init_data->fcnt_exp;
    int8_t *phs_center = init_data->phs_center;
    uint8_t *ad9781_smp = init_data->ad9781_smp;

    // enable PWR_EN
    SET_SFR1(g_base_sfr, SFR_OUT_REG0, SFR_OUT_BIT_PWR_ENB, 0);

    //------------------------------
    // LMK01801 init (CLK)
    //------------------------------
    init_zest_clocks(p_lmk01801_data);
    p &= check_zest_pll(); pass &= p;
    p &= check_zest_freq(ZEST_FREQ_DSP_CLK, fcnt_exp[ZEST_FREQ_DSP_CLK]); pass &= p;
    printf("==== ZEST DSP CLK Freq====  : %s.\n", p?"PASS":"FAIL");

    //------------------------------
    // AD9653 init (ADC)
    //------------------------------
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0x0, 0x3c); // soft reset
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0x100, 0x46); // sample override to 125MSPS
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xff, 1); // init sample override
    write_zest_regs(ZEST_DEV_AD9653_BOTH, p_ad9653_data->regmap, p_ad9653_data->len);
    p = true;
    for (ix=0; ix<2; ix++) {
        debug_printf("  --- Checking ADC: AD9653 %d\n", ix);
        p &= check_zest_regs(g_zest_adcs[ix], p_ad9653_data); pass &= p;
    }
    printf("==== ZEST ADC(AD9653) ====  : %s.\n", p?"PASS":"FAIL");

    dump_zest_adc_regs();

    //------------------------------
    // AD9781 init (DAC)
    //------------------------------
    reset_ad9781();
    write_zest_reg(ZEST_DEV_AD9781, 0x0, 0x20); // soft reset
    write_zest_regs(ZEST_DEV_AD9781, p_ad9781_data->regmap, p_ad9781_data->len);
    debug_printf("  --- Checking DAC: AD9781...\n");
    p = check_zest_regs(ZEST_DEV_AD9781, p_ad9781_data); pass &= p;
    printf("==== ZEST DAC(AD9781) ====  : %s.\n", p?"PASS":"FAIL");

    dump_zest_dac_regs();

    //------------------------------
    // AD7794 (Slow ADC)
    //------------------------------
    reset_ad7794();
    write_zest_regs(ZEST_DEV_AD7794, p_ad7794_data->regmap, p_ad7794_data->len);
    debug_printf("  --- Checking Slow ADC: AD7794...\n");
    p = check_zest_regs(ZEST_DEV_AD7794, p_ad7794_data); pass &= p;
    printf("==== ZEST AD7794      ====  : %s.\n", p?"PASS":"FAIL");

    //------------------------------
    // AMC7823 (8ADC+8DAC)
    //------------------------------
    write_zest_reg(ZEST_DEV_AMC7823, ((1<<6)|0xc), 0xbb30); // reset
    write_zest_regs(ZEST_DEV_AMC7823, p_amc7823_data->regmap, p_amc7823_data->len);
    debug_printf("  --- Checking Slow ADC/DAC: AMC7823...\n");
    p = check_zest_regs(ZEST_DEV_AMC7823, p_amc7823_data); pass &= p;
    printf("==== ZEST AMC7823     ====  : %s.\n", p?"PASS":"FAIL");

    //------------------------------
    // Align DAC_DCO_CLK and dsp_clk
    //------------------------------
    p = check_zest_freq(ZEST_FREQ_DAC_DCO, fcnt_exp[ZEST_FREQ_DAC_DCO]); pass &= p;
    printf("  Clock %s Freq Check: %s.\n",
        zest_fcnt_names[ZEST_FREQ_DAC_DCO], p?"PASS":"FAIL");
    p = align_dsp_clk_phase(phs_center[ZEST_FREQ_DAC_DCO]); pass &= p;
    printf("  Clock %s Phase Check: %s.\n",
        zest_phdiff_names[ZEST_FREQ_DAC_DCO], p?"PASS":"FAIL");

    //------------------------------
    // Align clk_div
    //------------------------------
    for (ix=0; ix<2; ix++) {
        p = check_zest_freq(ix, fcnt_exp[ix]); pass &= p;
        printf("  Clock %s Freq Check: %s.\n",
            zest_fcnt_names[ix], p?"PASS":"FAIL");
        p = align_adc_clk_phase(ix, phs_center[ix]); pass &= p;
        printf("  Clock %s Phase Check: %s.\n",
            zest_phdiff_names[ix], p?"PASS":"FAIL");
    }

    //------------------------------
    // ADC LVDS init
    //------------------------------
    p = init_zest_adcs(g_base_adc, -1); pass &= p;
    printf("==== ZEST ADC LVDS    ====  : %s.\n", p?"PASS":"FAIL");
    setup_waveform(g_base_wfm, 16);  // diagnostics

    //------------------------------
    // ADC PN9 validation
    //------------------------------
    p = check_adc_prbs9(); pass &= p;
    printf("==== ZEST ADC PN9 Check==== : %s.\n", p?"PASS":"FAIL");

    //------------------------------
    // DAC SMP alignment and BIST
    //------------------------------
    p = align_ad9781(ad9781_smp); pass &= p;
    printf("==== ZEST DAC SMP Check==== : %s.\n", p?"PASS":"FAIL");
    p = check_ad9781_bist(); pass &= p;
    printf("==== ZEST DAC BIST Check=== : %s.\n", p?"PASS":"FAIL");
    printf("==== Overall Zest INIT ==== : %s.\n", pass?"PASS":"FAIL");
    return pass;
}

bool check_adc_prbs9(void) {
    bool pass=true;
    uint16_t wfm_buf[16];
    uint16_t pn_buf[64];
    unsigned int ix;

    gen_prbs9(pn_buf, 64);
    for (ix=0; ix<64; ix++) {
        debug_printf("PN9: %#06x\n", pn_buf[ix]);
    }
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0x14, 0x06); // offset binary
    for (uint8_t ch=0; ch<8; ch++) {
        write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xd, 0x16);  // PN9 test pat
        write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xd, 0x06);  // PN9 test pat
        select_waveform_chan(g_base_wfm, ch);
        trigger_waveform(g_base_wfm);
        read_adc_waveform(wfm_buf, 8);
        debug_printf("ADC chan %d waveform:\n", ch);
        for (ix=0; ix<8; ix++) {
            debug_printf("  ix %2d, dout: %#06x\n", ix, wfm_buf[ix]);
        }
        for (ix=0; ix<64-8; ix++) {
            if (pn_buf[ix] == wfm_buf[0]) {
                // See gen_prbs9() for starting point of 1504
                // 1e3 / DSP_FREQ_MHZ / 8 is about 1.1 ns per bit
                printf("  ADC %d: Found PN9 offset=%u\n", ch, ix+1504);
                for (size_t iy=1; iy<8; iy++) {
                    pass &= pn_buf[ix+iy] == wfm_buf[iy];
                }
                break;
            } else if (ix == 55) { // 64 - 8 - 1
                printf("  ADC %d: Failed to find PN9.\n", ch);
            }
        }
    }
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xd, 0x0);   // normal ADC
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0x14, 0x07); // two's comp
    return pass;
}

void test_adc_pn9(uint8_t len) {
    uint16_t wfm_buf[16];
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0x14, 0x06); // offset binary
    for (uint8_t ch=0; ch<8; ch++) {
        write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xd, 0x16);  // PN9 test pat
        write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xd, 0x06);  // PN9 test pat
        select_waveform_chan(g_base_wfm, ch);
        trigger_waveform(g_base_wfm);
        printf("ADC chan %d waveform:\n", ch);
        read_adc_waveform(wfm_buf, len);
        for (unsigned int ix=0; ix<len; ix++) {
            printf("  ix %2u, dout: %#06x\n",ix, wfm_buf[ix]);
        }
    }
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0xd, 0x0);   // normal ADC
    write_zest_reg(ZEST_DEV_AD9653_BOTH, 0x14, 0x07); // two's comp
}

bool init_zest_dbg(uint32_t base, zest_init_t *init_data) {
    bool pass=true;
    // uint32_t fcnt;
    select_zest_addr(base);

    // zest_init_data_t *p_ad9653_data = &(init_data->ad9653_data);
    // printf("Reset BUFR 0: ");
    // reset_zest_bufr(0);
    // printf("Reset BUFR 1: ");
    // reset_zest_bufr(1);
    // printf("ZEST ADC init : ");
    // write_zest_regs(ZEST_DEV_AD9653_BOTH, p_ad9653_data->regmap, p_ad9653_data->len);

    // test_adc_pn9(8);
    // check_adc_prbs9();
    // align_ad9781(12);
    // uint32_t *fcnt_exp = init_data->fcnt_exp;
    // check_zest_freq(0, fcnt_exp[0]);
    // fcnt = read_zest_fcnt(0);
    // print_udec_fix(fcnt*125, FCNT_WIDTH, 3);
    check_ad9781_bist();
    return pass;
}
