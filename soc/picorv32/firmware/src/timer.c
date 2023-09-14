#include "timer.h"
#include "settings.h"

static uint32_t timerStartValue = 0;

// Returns number of CPU cycles since power up
uint32_t getCycles(void) {
    uint32_t ncycles;
    __asm__ volatile( "rdcycle %0;" : "=r"(ncycles) );
    return ncycles;
}

// Set timer ticks to zero
void resetTimer(void){
    timerStartValue = getCycles();
}

// Get timer ticks in cycles. This handles a single rollover just fine!
uint32_t getTimer(void){
    return ( getCycles() - timerStartValue );
}

// Block for `nCycles` clock cycles,
void delayCycles( const uint32_t nCycles ){
    uint32_t curValue, startValue = getCycles();
    do {
      curValue = getCycles();
      curValue -= startValue;
    } while( curValue < nCycles );
}

/* uint32_t millis(void) */
/* { */
/*     uint64_t cs = _picorv32_rd_cycle_64(); */
/*     return cs / (F_CLK / 1000); */
/* } */

int periodic_delay(unsigned cycles)
{
    static unsigned ts_a = 0;
    unsigned dt = getCycles() - ts_a;
    if (dt < cycles)
        delayCycles(cycles - dt);
    ts_a = getCycles();
    return cycles - dt;
}
