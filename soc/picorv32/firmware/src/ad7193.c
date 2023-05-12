#include "print.h"
#include "spi.h"
#include "ad7193.h"

static uint32_t adcValues[8] = {0, 0, 0, 0, 0, 0, 0, 0};

bool AD7193_GetReady() {
    return !CHECK_BIT(SPI_GET_STATUS(AD7193_ADDR), BIT_MISO);
}

void AD7193_SetReg(uint8_t addr, uint32_t data) {
    uint32_t reg = ((addr & 0x7) << 27) | (data & 0xffffff);
    SPI_SET_DAT_BLOCK(AD7193_ADDR, reg);
}

uint32_t AD7193_GetReg24(uint8_t addr) {
    uint32_t reg = (((addr & 0x7) << 3) | 0x40) << 24;
    SPI_SET_DAT_BLOCK(AD7193_ADDR, reg);
    return SPI_GET_DAT(AD7193_ADDR) & 0xffffff;
}

uint32_t AD7193_GetReg8(uint8_t addr) {
    uint32_t reg = (((addr & 0x7) << 3) | 0x40) << 8;
    SPI_INIT(AD7193_ADDR, 1, 0, 1, 1, 0, 16, 11);  // cpol=1, cpha=1, min 100ns high
    SPI_SET_DAT_BLOCK(AD7193_ADDR, reg);
    SPI_INIT(AD7193_ADDR, 1, 0, 1, 1, 0, 32, 11);  // cpol=1, cpha=1, min 100ns high
    return SPI_GET_DAT(AD7193_ADDR) & 0xff;
}

uint32_t AD7193_GetData() {
    SPI_INIT(AD7193_ADDR, 1, 0, 1, 1, 0, 8, 11);
    SPI_SET_DAT_BLOCK(AD7193_ADDR, 0x58);
    SPI_INIT(AD7193_ADDR, 1, 0, 1, 1, 0, 32, 11);
    return AD7193_GetDataContinuous();
}

uint32_t AD7193_GetDataContinuous() {
    AD7193_WaitReady();
    SPI_SET_DAT_BLOCK(AD7193_ADDR, 0);
    return SPI_GET_DAT(AD7193_ADDR);
}

uint32_t * AD7193_GetDataContinuousArray() {
    int ix;
    uint32_t val;

    for (ix = 0; ix < 8; ix++) {
        val = AD7193_GetDataContinuous();
        adcValues[val & 0xf] = val >> 8;
    };
    return adcValues;
}

void AD7193_PrintStatus() {
    uint8_t reg;
    reg = AD7193_GetReg8(AD7193_REG_STATUS);
    print_str("ad7193_status:   ");
    print_hex(reg, 2);
    _putchar('\n');
}

uint32_t AD7193_WaitReady() {
    uint32_t count=0;
    while (!AD7193_GetReady()) {
        if (++count > 600000 ) {
            print_str("AD7193 wait expired 600000.\n");
            break;
        }
    }
    return count;
}

char AD7193_Init() {
    uint32_t reg;
    uint32_t count;
    uint8_t ix;

    // Reset chip
    SPI_INIT(AD7193_ADDR, 1, 0, 1, 1, 0, 8, 11);
    for (ix=0; ix<5; ix++) SPI_SET_DAT_BLOCK(AD7193_ADDR, 0xff);
    count = AD7193_WaitReady();
    print_dec(count);
    _putchar('\n');

    // Get ID
    reg = AD7193_GetReg8(AD7193_REG_ID);
    if ((reg & AD7193_ID_MASK) != ID_AD7193) {
        print_str("ad7193_id read failed.\n");
        print_str("ad7193_id  :     ");
        print_hex(reg, 2);
        //return -1;
    } else {
        print_str("ad7193_id  :     ");
        print_hex(reg, 2);
        _putchar('\n');
    }

    SPI_INIT(AD7193_ADDR, 1, 0, 1, 1, 0, 32, 11);  // cpol=1, cpha=1, min 100ns high
    AD7193_SetReg(AD7193_REG_CONF, AD7193_CONF_DEFAULT);
    AD7193_SetReg(AD7193_REG_MODE, AD7193_MODE_DEFAULT);

    reg = AD7193_GetReg24(AD7193_REG_MODE);
    print_str("ad7193_mode:     ");
    print_hex(reg, 6);
    _putchar('\n');

    reg = AD7193_GetReg24(AD7193_REG_CONF);
    print_str("ad7193_conf:     ");
    print_hex(reg, 6);
    _putchar('\n');

    AD7193_PrintStatus();

    // enter continuous sampling mode
    AD7193_SetReg(AD7193_REG_COMM, 0x5c0000);
    return 0;
}
