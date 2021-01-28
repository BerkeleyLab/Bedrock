#ifndef TIMER_H
#define TIMER_H
//-------------------------------------------------------------
// A basic timer API based on the RISCV rdcycle register
//-------------------------------------------------------------
#include <stdint.h>
#include "settings.h"

// Convert microseconds to clock cycles
#define US_TO_CYCLES(usecs) (1LL*F_CLK*(usecs)/1000000)

// Delay in microseconds. Accurate starting from usecs=1
#ifdef SIMULATION
#define DELAY_US(usecs) ;
#else
#define DELAY_US(usecs) delayCycles( US_TO_CYCLES(usecs) - 45 )
#endif

// Delay in milliseconds
#define DELAY_MS(msecs) DELAY_US(msecs*1000)

// Returns number of CPU cycles since power up as 32 bit number
uint32_t getCycles(void);

// Returns number of CPU cycles since power up as 64 bit number
extern uint64_t _picorv32_rd_cycle_64(void);

// Elapsed time since power up in [ms]
uint32_t millis(void);

// Set timer ticks to zero
void resetTimer(void);

// Get timer ticks. This handles a single timer rollover just fine!
uint32_t getTimer(void);

// Block for `nCycles`, ~45 cycles overhead
void delayCycles(const uint32_t nCycles);

// when called in a loop, makes sure each iteration takes
// the same amount of time (at least `cycles` between calls)
// returns the number of blocked cycles (IDLE time)
int periodic_delay(unsigned cycles);

#endif
