#ifndef IDELAY_H
#define IDELAY_H

// IDELAY settings
#define IDELAY_REF_CLK  (200.0 * 1000 * 1000)            //[Hz]
#define CLK_AB_FREQ     (229.0 * 1000 * 1000)            //[Hz]
#define IDELAY_RES      (1.0 / 32 / 2 / IDELAY_REF_CLK)  // delay per digit [s]
// Distance from either edge to sample point [s]
#define IDELAY_DIST_S   (1.0/CLK_AB_FREQ/4)
// Distance from either edge to sample point [idelay taps.]
#define IDELAY_DIST_VAL ((unsigned)(IDELAY_DIST_S/IDELAY_RES))

// Prints a visual eye-diagram on the UART
// (received bit value as a function of idelay tap value)
// evenOddBits: 0 = show all even bits (on clk_ab rising edge),
//              1 = show all odd bits (on clk_ab falling edge)
void printEye( unsigned evenOddBits );

// Finds the edge in the eye diagram.
// Expects 0x1555 static test pattern!
// Returns suggested iDelay to sample in the middle.
// Or -1 if no edge is found
// bit = [0 .. 27]
int getBitDelay( unsigned bit );

// Tries to set all 14 idelays to their recommended value
// returns 0 on success, negative on error
unsigned setIdelays( void );

#endif
