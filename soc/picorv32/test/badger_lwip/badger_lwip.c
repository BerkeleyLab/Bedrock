// Demonstrate LWIP on an picorv32 soft-core emulated by verilator
//   * follow notes in Makefile to setup tap0 interface
//   * run the code with `make all` or `make badger_lwip.vcd` to debug hardware
//   * sends a UDP packet to 192.168.7.1:1234, receive it with `nc -u -l -p 1234`
//   * runs a web-server on port 80 to demonstrate TCP,
//     open http://192.168.7.13/ in a web-browser
//   * debug message settings and lwip configuration is in liblwip/lwipopts.h
//   * to demonstrate DHCP, uncomment `dhcp_start(&netif);` and run a DHCP server
//     on the local TAP0 network
#include <stdint.h>

// Picorv library
#include "settings.h"
#include "common.h"
#include "sfr.h"
#include "printf.h"
#include "badger.h"

// lwIP badger port
#include "arch/cc.h"
#include "lwipopts.h"
#include "badgerif.h"

// lwIP core includes
#include "lwip/sys.h"
#include "lwip/timeouts.h"
#include "lwip/debug.h"
#include "lwip/stats.h"
#include "lwip/init.h"
#include "lwip/tcpip.h"
#include "lwip/netif.h"
#include "lwip/api.h"
#include "lwip/ip_addr.h"

// LWIP apps
#include "lwip/dhcp.h"
#include "lwip/apps/httpd.h"

// To make printf() show up in the terminal
void _putchar(char c){
	SET_REG8(BASE_CONSOLE, c);
}

int main(void) {
    struct netif netif;
    ip_addr_t myIp, mySubnet, destIp;
    IP_ADDR4(&myIp, 192, 168, 7, 13);
    IP_ADDR4(&mySubnet, 255, 255, 255, 0);
    IP_ADDR4(&destIp, 192, 168, 7, 1);

    lwip_init();
    netif_add(&netif, &myIp, &mySubnet, NULL, NULL, badger_init, netif_input);

    // Set MAC addr
    netif.hwaddr[0] = 0x7A;
    netif.hwaddr[1] = 0x4D;
    netif.hwaddr[2] = 0x94;
    netif.hwaddr[3] = 0xFA;
    netif.hwaddr[4] = 0x87;
    netif.hwaddr[5] = 0x61;

    netif_set_up(&netif);
    netif_set_link_up(&netif);

    // Prepare a UDP packet, which will be sent to destIp
    struct udp_pcb *pcb = udp_new();
    char msg[] = "pi is exactly three!!!\n";
    struct pbuf *pb = pbuf_alloc(PBUF_TRANSPORT, sizeof(msg), PBUF_RAM);
    memcpy(pb->payload, msg, sizeof(msg));

    // Start DHCP and HTTPD (optional)
    // dhcp_start(&netif);
    httpd_init();

    unsigned i = 0;
    while (1) {
        // send a single UDP packet
        if (i == 10) {
            udp_sendto(pcb, pb, &destIp, 1234);
            pbuf_free(pb);
            pb = NULL;
        }

        // Check for received frames, feed them to lwIP
        badger_input(&netif);

        // Cyclic lwIP timers check
        sys_check_timeouts();
        i++;
    }

    return 0;
}
