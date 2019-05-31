#include "onewire_soft.h"
#include "common.h"
#include "print.h"

#define DEBUG_CONSOLE_BASE 0x02

void _putchar( char c ){
    SET_REG( DEBUG_CONSOLE_BASE << 24, c);
}

int main(void) {
    uint8_t testData[8];
    // Must match parameter rom in ds1822.v
    uint8_t wantData[] = {0x01, 0x8e, 0x2f, 0xe5, 0x08, 0x00, 0x00, 0xbe};

    onewire_init();
    onewire_reset();

    onewire_tx( 0x33 );  // Read ROM
    for (int i=0; i<8; i++) {
        testData[i] = onewire_tx( 0xff );
    }
    _putchar( 'O' );
    _putchar( 'W' );
    _putchar( ' ' );

    int pass=1;
    for (int i=7; i>=0; i--) {
        print_hex( testData[i], 2);
        if (testData[i] != wantData[i]) pass=0;
    }
    _putchar( '\n' );
    return pass;
}
