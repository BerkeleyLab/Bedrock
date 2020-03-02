#ifndef __BADGERIF_H__
#define __BADGERIF_H__

#include <lwip/netif.h>

void badger_input(struct netif *netif);
err_t badger_init(struct netif *netif);

#endif /* __LITEETH_IF_H__ */
