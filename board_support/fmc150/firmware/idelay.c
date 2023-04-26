// These functions work with the FMC150 ADC

#include <stdint.h>
#include "fmc150.h"
#include "settings.h"
#include "timer.h"
#include "ads62p49.h"
#include "idelay.h"
#include "common.h"
#include "print.h"

int getBitDelay( unsigned bit )
{
    unsigned lane = bit / 2;
    unsigned bitMask = 1<<(bit%14);
    int lastVals = 0, val;
    for( unsigned i=0; i<=31; i++){     // for each delay value
        ADS62P49_SET_IDELAY(lane, i );
        DELAY_US(10);
        // Evaluate static test pattern
        val = (ADS62P49_GET_SAMPLES((lane>6),0)&bitMask) != 0;
        // Logic is inverted for odd bits
        if( bit & 0x01 ) val = !val;
        lastVals = (lastVals<<1) | val;
        if( i > 0 ){
            switch( lastVals & 0x03 ){
                case 0b01:  // Found leading data edge
                    return MIN(i+IDELAY_DIST_VAL, 31);
                case 0b10:  // Found trailing data edge
                    return MAX(i-IDELAY_DIST_VAL,  0);
            }
        }
    }
    // No edge found, return -1  :(
    return -1;
}

t_fmc150Error setIdelays( void )
{
    int bitDel1, bitDel2, bitDel, retVal=RET_OK;
    print_str("setIdelays() [");
    for( unsigned lane=0; lane<=13; lane++){ // for each LVDS lane
        // Average the idelay settings from even and odd bits
        bitDel1 = getBitDelay(2*lane);
        bitDel2 = getBitDelay(2*lane+1);
        if( bitDel1 >= 0 && bitDel2 >= 0 ){
            bitDel = ( bitDel1 + bitDel2 ) / 2;
            ADS62P49_SET_IDELAY( lane, bitDel );
            print_dec( bitDel );
            print_str((lane<13) ? ", " : "");
        } else {
            print_str("\nError: idelay[");
            print_dec( lane );
            print_str("] couldn't find edge!");
            retVal = RET_ERR_ADC_IDEL;
        }
    }
    print_str("] ");
    return retVal;
}

void printEye( unsigned evenOddBits )
{
    print_str(evenOddBits?"Even bits (pos. clk. edge)\n":"Odd bits (neg. clk. edge)\n");
    for( unsigned lane=0; lane<=13; lane++){ // for each LVDS lane
        int backupDelayVal=0;
        unsigned bit = (2*lane+evenOddBits)%14;
        unsigned bitMask = 1<<bit;
        print_str("Lane "); print_hex(lane,1);
        print_str(" (bit "); print_hex(bit,1); print_str("): ");
        ADS62P49_GET_IDELAY( lane, backupDelayVal );
        for( int i=0; i<=31; i++){          // for each delay value
            if( i==backupDelayVal ){
                _putchar('x');
            } else {
                ADS62P49_SET_IDELAY(lane, i );
                // Evaluate dynamic test pattern (raw)
                // _putchar( (ADS62P49_GET_SAMPLES((lane>6),0)&bitMask) ? '1' : '0' );
                // _putchar( (ADS62P49_GET_SAMPLES((lane>6),1)&bitMask) ? '1' : '0' );
                // _putchar(' ');
                // Evaluate dynamic test pattern
                // unsigned a = ADS62P49_GET_SAMPLES((lane>6),0)&bitMask;
                // unsigned b = ADS62P49_GET_SAMPLES((lane>6),1)&bitMask;
                // _putchar( (a>b) ? '1' : '.' );
                // Evaluate static test pattern (0x1555 or 0x2aaa)
                _putchar( (ADS62P49_GET_SAMPLES((lane>6),0)&bitMask) ? '1' : '.' );
            }
        }
        ADS62P49_SET_IDELAY(lane, backupDelayVal );
        _putchar(' ');
        print_dec( backupDelayVal );
        _putchar('\n');
    }
}
