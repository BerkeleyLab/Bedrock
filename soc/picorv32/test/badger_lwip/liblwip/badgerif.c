// based on example file: lwip/contrib/examples/ethernetif/ethernetif.c

#include <lwip/netif.h>
#include <lwip/opt.h>
#include <lwip/mem.h>

#include <netif/etharp.h>
#include "badgerif.h"

#include "common.h"
#include "sfr.h"
#include "settings.h"
#include "badger.h"
#include "print.h"

sys_prot_t sys_arch_protect(void) { return 1; }

void sys_arch_unprotect(sys_prot_t pval) { LWIP_UNUSED_ARG(pval); }

/**
 * This function should do the actual transmission of the packet. The packet is
 * contained in the pbuf that is passed to the function. This pbuf
 * might be chained.
 *
 * @param netif the lwip network interface structure for this ethernetif
 * @param p the MAC packet to send (e.g. IP packet including MAC addresses and type)
 * @return ERR_OK if the packet could be sent
 *         an err_t value if the packet couldn't be sent
 *
 * @note Returning ERR_MEM here if a DMA queue of your MAC is full can lead to
 *       strange results. You might consider waiting for space in the DMA queue
 *       to become available since the stack doesn't retry to send a packet
 *       dropped because of memory failure (except for the TCP timers).
 */
static err_t badger_output(struct netif *netif, struct pbuf *p)
{
    LWIP_UNUSED_ARG(netif);
    struct pbuf *q;
    // Wait for eventual previous TX to finish
    if (GET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_TX_START)) {
        while(!GET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_TX_DONE));
        SET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_TX_START, 0);
    }

    // start_addr refers to an offset to BASE_BADGER_TX in [16 bit words]
    SET_REG16(BASE_BADGER_SFR, 0);

    // Write data to memory where badger will expect it
    // first 16 bit word is packet length (will be set later)
    uint8_t *buf_tx = (uint8_t*)(BASE_BADGER_TX + 2);

    unsigned txlen = 0;
    q = p;
    // pbuf is a linked list, go trough each item
    // and copy its payload into buf_tx
    while(q) {
        memcpy(buf_tx, q->payload, q->len);
        buf_tx += q->len;
        txlen += q->len;
        if(q->tot_len != q->len)
            q = q->next;
        else
            q = NULL;
    }

    // first 16 bit word is packet length
    buf_tx = (uint8_t*)(BASE_BADGER_TX);
    buf_tx[0] = txlen;
    buf_tx[1] = txlen >> 8;

    // Put the packet on the wire
    SET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_TX_START, 1);
    return ERR_OK;
}

/**
 * Should allocate a pbuf and transfer the bytes of the incoming
 * packet from the interface into the pbuf.
 *
 * @param netif the lwip network interface structure for this ethernetif
 * @return a pbuf filled with the received packet (including MAC header)
 *         NULL on memory error
 */
void badger_input(struct netif *netif)
{
    struct pbuf *p, *q;
    // check for new data
    if(!GET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_RX_NEW_DATA))
        return;

    // swap buffers, make new data visible
    SET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_RX_BUF_SWAP, 0);
    unsigned rx_len = badger_rx_len();
    uint8_t *buf_rx = (uint8_t *)(BASE_BADGER_RX + BADGE_LEN);
    LINK_STATS_INC(link.recv);

    // get a linked list of lwip buffers to copy data into
    p = pbuf_alloc(PBUF_RAW, rx_len, PBUF_POOL);
    q = p;
    while (q) {
        memcpy(q->payload, buf_rx, q->len);
        buf_rx += q->len;
        if(q->tot_len != q->len)
            q = q->next;
        else
            q = NULL;
    }

    if (p){
        if (netif->input(p, netif) != ERR_OK) {
            printf("Error inputting packet!!!\n");
            pbuf_free(p);
            p = NULL;
        };
    }
}

/**
 * In this function, the hardware should be initialized.
 * Called from ethernetif_init().
 *
 * @param netif the already initialized lwip network interface structure
 *        for this ethernetif
 */
err_t badger_init(struct netif *netif)
{
    netif->hwaddr_len = ETH_HWADDR_LEN;
    for(unsigned i = 0; i < netif->hwaddr_len; i++)
        netif->hwaddr[i] = i;   // TODO manage mac address
    netif->mtu = 1514;
    netif->name[0] = 'p';   //Packet Badger
    netif->name[1] = 'b';
    netif->flags |= NETIF_FLAG_BROADCAST | NETIF_FLAG_ETHERNET | NETIF_FLAG_ETHARP;

    netif->output = etharp_output;
    netif->linkoutput = badger_output;
    // Enable hardware MAC
    SET_SFR1(BASE_BADGER_SFR, 0, BIT_BADGER_RX_ACCEPT, 1);
    return ERR_OK;
}

// Returns the current time in milliseconds
u32_t sys_now(void)
{
    // Note that 32 bit will overflow in about 30 s at 125 MHz
    // ... might cause problems
    unsigned ncycles;
    __asm__ volatile( "rdcycle %0;" : "=r"(ncycles) );
    return ncycles / (F_CLK / 1000);
}
