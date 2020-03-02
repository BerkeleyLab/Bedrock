#include "mdio.h"
#include <stdint.h>
#include <stdbool.h>
#include "gpio.h"
#include "timer.h"
#include "settings.h"
#include "common.h"
#include "print.h"

#define MDIO_DELAY() DELAY_US( MDIO_DELAY_US )
#define SET_MDIO(val) SET_GPIO1( BASE_GPIO, GPIO_OE_REG, PIN_PHY_MDIO, val ? 0 : 1)
#define MDIOR()  GET_GPIO1( BASE_GPIO, GPIO_IN_REG, PIN_PHY_MDIO)

#define MDC1() {SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, PIN_PHY_MDC, 1 ); MDIO_DELAY();}
#define MDC0() {SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, PIN_PHY_MDC, 0 ); MDIO_DELAY();}

void mdio_init(void){
    // configure MDC and RESET PIN
    SET_GPIO1( BASE_GPIO, GPIO_OE_REG, PIN_PHY_MDC, 1 );
    SET_GPIO1( BASE_GPIO, GPIO_OE_REG, PIN_PHY_RESET_B, 1 );

    // reset phy
    SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, PIN_PHY_RESET_B, 0 );
    DELAY_US(MDIO_RESET_US);
    SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, PIN_PHY_RESET_B, 1 );

    // pin signals alternate between 0 and Z, so clear the gpioOut bits
    SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, PIN_PHY_MDIO, 0 );
    SET_MDIO(0);
    MDC0();
}

void mdio_tx32(const uint32_t dat) {
    bool bit;
    for (size_t i=32; i; i--){
        bit = CHECK_BIT(dat, i-1);
        SET_MDIO(bit);
        MDC0();
        MDC1();
    }
}

uint16_t mdio_rx(void) {
    uint16_t dat = 0;
    for (int i=0; i<16; i++ ){
        dat <<= 1;
        dat |= MDIOR();
        MDC0();
        MDC1();
    }
    return dat;
}

void mdio_start(void){
    mdio_tx32(0xffffffff);
}

void mdio_stop(void){
    SET_MDIO(1);
    MDC0();
    MDC1();
    MDC0();
}

void mdio_write_reg( uint8_t phyAddr, uint8_t regAddr, uint16_t regVal) {
    uint16_t assem = 0;
    assem = MDIO_ST<<14 | MDIO_OP_W<<12 | (phyAddr & 0x1f)<<7 | (regAddr & 0x1f)<<2 | MDIO_TA;
    mdio_start();
    mdio_tx32(assem<<16 | regVal);
    mdio_stop();
}

uint16_t mdio_read_reg( uint8_t phyAddr, uint8_t regAddr) {
    uint16_t assem = 0;
    uint16_t dat = 0;
    bool bit;

    assem = MDIO_ST<<14 | MDIO_OP_R<<12 | (phyAddr & 0x1f)<<7 | (regAddr & 0x1f)<<2 | 0;
    mdio_start();
    for (size_t i=16; i>2; i-- ){
        bit = CHECK_BIT(assem, i-1);
        SET_MDIO(bit);
        MDC0();
        MDC1();
    }
    SET_MDIO(1);
    MDC0();
    MDC1();
    MDC0();
    MDC1();
    dat = mdio_rx();
    mdio_stop();
    return dat;
}
