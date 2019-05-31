#include <stdint.h>
#include "gpio.h"
#include "timer.h"
#include "settings.h"
#include "common.h"
#include "onewire_soft.h"

//-------------------------------------------------
// Private macros /functions
//-------------------------------------------------
// setting / clearing / reading the Onewire pin
#define OW_PIN_SET(x) { SET_GPIO1( BASE_GPIO, GPIO_OE_REG, PIN_ONEWIRE, x ); }
#define OW_PIN_GET()    GET_GPIO1( BASE_GPIO, GPIO_IN_REG, PIN_ONEWIRE )

//-------------------------------------------------
// Low level functions
//-------------------------------------------------
void onewire_init(void)
{
    // Onewire pin signals alternate between 0 and Z, so clear the gpioOut bits
    OW_PIN_SET(0);
    SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, PIN_ONEWIRE, 0 );
}

// Returns number of CPU cycles since power up
static uint32_t local_getCycles(void) {
    uint32_t ncycles;
    __asm__ volatile( "rdcycle %0;" : "=r"(ncycles) );
    return ncycles;
}

static void onewire_stall(uint32_t et)
{
    uint32_t cur_t;
    do {
        cur_t = local_getCycles();
    } while (cur_t < et);
}

// Returns "presence"
int onewire_reset(void)
{
    uint32_t st = local_getCycles();        OW_PIN_SET(1);
    onewire_stall(st + US_TO_CYCLES(540));  OW_PIN_SET(0);
    onewire_stall(st + US_TO_CYCLES(600));  int r = OW_PIN_GET();
    onewire_stall(st + US_TO_CYCLES(990));  return r;
}

static int onewire_bit(int x)
{
    uint32_t st = local_getCycles();       OW_PIN_SET(1);
    onewire_stall(st + US_TO_CYCLES(5) );  OW_PIN_SET(!x);
    onewire_stall(st + US_TO_CYCLES(10));  int r = OW_PIN_GET();
    onewire_stall(st + US_TO_CYCLES(65));  OW_PIN_SET(0);
    onewire_stall(st + US_TO_CYCLES(95));  return r;
}

// Use onewire_tx(0xff) for reads
int onewire_tx( uint8_t dat )
{
    int r=0;
    for (unsigned i=0; i<=7; i++ ){
        r = (r>>1) + (onewire_bit(dat & 0x01)<<7);
        dat >>= 1;
    }
    return r;
}
