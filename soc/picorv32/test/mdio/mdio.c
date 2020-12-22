#include <stdint.h>
#include "settings.h"
#include "gpio.h"
#include "timer.h"
#include "mdio.h"

int main(void) {
    mdio_init();
    mdio_write_reg( 0x10, 0x01, 0xdead);
    mdio_read_reg( 0x10, 0x01);

    return 0;
}
