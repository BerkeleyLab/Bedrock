#include <string.h>
#include "settings.h"
#include "onewire_soft.h"
#include "common.h"
#include "print.h"
#include "timer.h"

#define DEBUG_CONSOLE_BASE 0x02

void _putchar(char c)
{
    SET_REG(DEBUG_CONSOLE_BASE << 24, c);
}

int main(void)
{
    uint8_t testData[8];

    // Must match parameter rom in ds1822.v
    const uint8_t wantData_a[] = {0x01, 0x8e, 0x2f, 0xe5, 0x08, 0x00, 0x00, 0xbe};
    const uint8_t wantData_b[] = {0x56, 0x34, 0x12, 0x90, 0x78, 0x56, 0x34, 0x12};

    // Search is not supported by model yet
    // uint8_t adr[8];
    // if (onewire_search(adr)) {
    //  print_str("Found: ");
    //  for (unsigned i=0; i<sizeof(adr); i++)
    //      print_hex(adr[i], 2);
    //  _putchar('\n');
    // } else {
    //  print_str("Nothing found :(\n");
    // }
    // return -1;

    onewire_init(PIN_ONEWIRE_A);
    if (!onewire_readrom(testData)) {
        print_str("A: No presence");
        return -1;
    }
    hexDump(testData, 8);
    if (memcmp(testData, wantData_a, 8) != 0) {
        print_str("A: wrong ID");
        return -1;
    }
    if (onewire_crc8(testData, 7) != wantData_a[7]) {
        print_str("A: wrong CRC");
        return -1;
    }

    onewire_init(PIN_ONEWIRE_B);
    if (!onewire_readrom(testData)) {
        print_str("B: No presence");
        return -1;
    }
    hexDump(testData, 8);
    if (memcmp(testData, wantData_b, 8) != 0) {
        print_str("B: wrong ID");
        return -1;
    }

    return 1;
}
