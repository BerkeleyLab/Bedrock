#include <stdint.h>
#include <string.h>
#include "common.h"
#include "sfr.h"
#include "settings.h"
#include "badger.h"

void badger_tx(uint8_t *data, unsigned len, unsigned start_addr) {
    // Wait for previous TX to finish
    if (GET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_TX_START)) {
        while(!GET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_TX_DONE)) {};
        SET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_TX_START, 0);
    }
    // start_addr refers to an offset to BASE_BADGER_TX in [16 bit words]
    SET_REG16(BASE_BADGER_SFR, start_addr);
    // Write data to memory where badger will expect it
    uint8_t *buf_tx = (uint8_t*)(BASE_BADGER_TX + start_addr * 2);
    // first 16 bit word is packet length
    *buf_tx++ = len;
    *buf_tx++ = len >> 8;
    memcpy(buf_tx, data, len);
    // Start new TX
    SET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_TX_START, 1);
    // TODO avoid 8 bit access as it is slow
}

unsigned badger_rx_len(void) {
    unsigned pack_len; //, status_r;
    // decode the badge (internal packet header)
    pack_len = (GET_REG8(BASE_BADGER_RX) & 0x7F);
    pack_len |= (GET_REG8(BASE_BADGER_RX + 1) & 0x0F) << 7;
    // status_r = GET_REG8(BASE_BADGER_RX + 2);
    return pack_len;
}

unsigned badger_block_rx(void) {
    // wait for packet to be received into the `invisible` half of the buffer
    while(!GET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_RX_NEW_DATA)) {};
    // swap buffers, make new data visible
    SET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_RX_BUF_SWAP, 0);
    return badger_rx_len();
}
