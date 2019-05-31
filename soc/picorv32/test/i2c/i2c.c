#include <stdint.h>
#include "settings.h"
#include "gpio.h"
#include "timer.h"
#include "i2c_soft.h"

int main(void) {
    uint8_t testData[8];

    i2c_init();

    // Read N bytes
    i2c_read_regs(0x42, 0x24, testData, sizeof(testData));

    // Send N bytes
    i2c_write_regs(0x42, 0x24, testData, sizeof(testData));

    return 0;
}
