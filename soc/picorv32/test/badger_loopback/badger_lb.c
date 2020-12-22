#include <stdint.h>
#include <stdlib.h>
#include <string.h>
// #include "common.h"  // using this and CFLAGS += -nostdlib cuts the program size by half
#include "sfr.h"
#include "gpio.h"
#include "print.h"
#include "settings.h"
#include "badger.h"

static uint8_t buf_tmp[64];

void badger_tx_test(unsigned len, unsigned start_addr) {
    // start_addr refers to an offset to BASE_BADGER_TX in [16 bit words]
    // static unsigned cnt = 0;
    // generate some test data
    for (unsigned i=0; i<len; i++)
        // buf_tmp[i] = cnt++;
        buf_tmp[i] = rand();
    badger_tx(buf_tmp, len, start_addr);
}

#define print_bit(x) {print_hex(GET_SFR1(BASE_BADGER_SFR, 0, x), 1); _putchar('\n');}
unsigned print_rx(void) {
    // returns 0 on fail, 1 on pass
    unsigned len = badger_rx_len();
    print_str("RX ["); print_hex(GET_REG(BASE_BADGER_SFR), 8); _putchar(']');
    // print_str("RX_CATEGORY: ");     print_hex((GET_REG(BASE_BADGER_SFR) >> BIT_BADGER_RX_CATEGORY) & 0b11, 1); _putchar('\n');
    // print_str("CRC_OK: ");          print_bit(BIT_BADGER_RX_CRC_OK);
    // print_str("DEST_MAC_MATCH: ");  print_bit(BIT_BADGER_RX_DEST_MAC_MATCH);
    // print_str("RX_VALID_IP: ");     print_bit(BIT_BADGER_RX_VALID_IP);
    // print_str("RX_UDP_V_PORT: ");   print_hex(GET_REG(BASE_BADGER_SFR) >> BIT_BADGER_RX_UDP_V_PORT, 1); _putchar('\n');
    // Check received data (without checksum) against buf_tmp
    if(memcmp((uint8_t *)(BASE_BADGER_RX + BADGE_LEN), buf_tmp, len - 4)) {
        print_str(" :( Compare error !!!\nREF:");
        // Print reference data
        hexDump(buf_tmp, len - 4);
        print_str("\nRX:");
        // Print received data
        hexDump((uint8_t *)(BASE_BADGER_RX + BADGE_LEN), len - 4);
        return 0;
    } else {
        print_str(" :)\n");
        return 1;
    }
}

// To make printf() show up in the terminal
void _putchar(char c){
	SET_REG8(BASE_CONSOLE, c);
}

int main(void) {
    unsigned pass = 1;
    SET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_RX_ACCEPT, 1);
    // Send (and loop back) 32 random numbers
    badger_tx_test(32, 0);
    // Wait for new data
    badger_block_rx();
    // check received data and print result
    pass &= print_rx();
    // send another 32, with an TX address offset this time
    badger_tx_test(48, 32);
    badger_block_rx();
    pass &= print_rx();
    // third time's a charm
    badger_tx_test(61, 40);
    badger_block_rx();
    pass &= print_rx();
    return pass;
    // TODO add interrupt on new data received
}
