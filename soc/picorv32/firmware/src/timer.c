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
