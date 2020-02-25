// Very Low level functions and register definitions
// to send / receive ethernet packets through the packet badger mac
// this layer sits between badger_pack.v and liblwip/badgerif.c

#include "settings.h"

#define BADGER_AW 10   // Address width
#define BADGE_LEN 4    // N bytes of internal header before rx payload

// Badger pack contains a TX, RX memory and a special function register (SFR)
#define BASE_BADGER_SFR (BASE_BADGER | 0x00000000)
#define BASE_BADGER_TX  (BASE_BADGER | 0x00010000)
#define BASE_BADGER_RX  (BASE_BADGER | 0x00020000)

// Bit definitions of the SFR
#define BIT_BADGER_TX_START 16
#define BIT_BADGER_RX_ACCEPT 17
#define BIT_BADGER_TX_DONE 18
#define BIT_BADGER_RX_BUF_SWAP 19
#define BIT_BADGER_RX_NEW_DATA 20
#define BIT_BADGER_RX_CATEGORY 24       // 2 bits, category: 3=UDP, 2=ICMP, 1=ARP, 0=other
#define BIT_BADGER_RX_CRC_OK 26         // CRC32 passed
#define BIT_BADGER_RX_DEST_MAC_MATCH 27 // Destination MAC matched our configuration
#define BIT_BADGER_RX_VALID_IP 28       // valid IP packet of some kind
#define BIT_BADGER_RX_UDP_V_PORT 29     // 3 bits, UDP virtual port number, output of CAM

// Alternative API
// Neat ... but will not make use single cycle SFR bit-wise memory access
// typedef union {
//     unsigned reg;
//     struct {
//         unsigned tx_start_addr: 16;
//         unsigned tx_start: 1;
//         unsigned rx_accept: 1;
//         unsigned tx_done: 1;
//         unsigned rx_buf_swap: 1;
//         unsigned rx_new_data: 1;
//         unsigned unused: 3;
//         unsigned rx_category: 2;         // 3=UDP, 2=ICMP, 1=ARP, 0=other
//         unsigned rx_crc_ok: 1;           // CRC32 passed
//         unsigned rx_dest_mac_match: 1;   // Destination MAC matched our configuration
//         unsigned rx_valid_ip: 1;         // valid IP packet of some kind
//         unsigned rx_udp_v_port: 3;       // UDP virtual port number, output of CAM
//     };
// } t_badger_rx_sfr

// Copy `data` into badger TX buffer at offset `start_addr` and send as payload
// Blocks if a TX is already in progress. CRC32 will be added.
void badger_tx(uint8_t *data, unsigned len, unsigned start_addr);

// returns length of last received packet, not counting the badge
unsigned badger_rx_len(void);

// block until RX, swap buffers, return pack_len
unsigned badger_block_rx(void);
