#include <stdint.h>
#include <stdbool.h>
#include "fmc150.h"
#include "settings.h"
#include "sfr.h"
#include "timer.h"
#include "spi.h"
#include "cdce72010.h"
#include "dac3283.h"
#include "ads62p49.h"
#include "amc7823.h"
#include "idelay.h"
#include "print.h"

// Toggle reset pins of all chips, set control pins to default values
static t_fmc150Error reset_fmc150( void ) {
    print_str("reset_fmc150()            ");
    // FMC present pin is active low
    if (GET_SFR1(BASE_FMC150_SFR,0,PIN_PRSNT_M2C_L)) return RET_ERR_NO_FMC;
    // Deselect all SPI chips
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_CDCE72010_NSS, 1 );
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_ADS62P49_NSS, 1 );
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_DAC3283_NSS, 1 );
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_AMC7823_NSS, 1 );
    // Reset chips
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_CDCE72010_NRST, 0 );
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_AMC7823_NRST,   0 );
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_ADS62P49_RST,   1 );
    // Come out of reset
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_CDCE72010_NRST, 1 );
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_AMC7823_NRST,   1 );
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_ADS62P49_RST,   0 );
    // Set power good to module
    SET_SFR1( BASE_FMC150_SFR, 0, PIN_FMC150_PG_C2M, 1 );
    CDCE72010_POWER_EN(0);
    CDCE72010_REF_EN(0);
    DAC3283_TXENABLE(0);
    return RET_OK;
}

// user can redefine this function if needed for custom error behavior
bool __attribute__((weak)) errorHook( t_fmc150Error errValue ){
    bool continueRunning = false;
    switch( errValue ){
        case RET_UNKNOWN:                       continueRunning=true; break;
        case RET_OK:          print_str("OK "); continueRunning=true; break;
        case RET_ERR_NO_FMC:  print_str("FMC150 not present ");       break;
        case RET_ERR_SPI:     print_str("spi error ");                break;
        case RET_ERR_ADC_IDEL:print_str("idelay error ");             break;
        case RET_ERR_DAC_TP:  print_str("DAC test pattern invalid "); break;
        case RET_ERR_DAC_CLK: print_str("DAC clk alarm!");            break;
        case RET_ERR_DAC_FIFO:print_str("DAC FIFO alarm!");           break;
        case RET_ERR_DAC_UNLOCKED: print_str("DAC MMCM unlocked! ");  break;
        default:
        case RET_ERR:
            print_str("general error (");
            print_dec( errValue );
            print_str(") ");
            break;
    }
    return continueRunning;
}

// Debug print helper
#define FMC150_PRNT_HLP( s ) { \
    print_str( s );            \
    print_hex( r, 2 );         \
    print_str(", ");           \
    print_hex( v,  8 );        \
    print_str(" ) ");          \
}

// Plays back an array of t_cfgReg and sends initialization data
// stops on deviceId == DEV_ILLEGAL
// returns true on success
bool init_fmc150( const t_cfgReg *reg ) {
    if( !reg ) return false;
    t_deviceId dev = FMC150_DEV_ILLEGAL;
    while( 1 ){
        t_fmc150Error retVal = RET_UNKNOWN;
        // Check if we speak to a different chip --> need to re-init SPI
        if( dev != reg->deviceId ){
            dev = reg->deviceId;
            switch( dev ){
                case FMC150_DEV_ADS62P49:
                    ADS62P49_SPI_INIT();
                    break;
                case FMC150_DEV_AMC7823:
                    AMC7823_SPI_INIT();
                    break;
                case FMC150_DEV_CDCE72010:
                    CDCE72010_SPI_INIT();
                    break;
                case FMC150_DEV_DAC3283:
                    DAC3283_SPI_INIT();
                    break;
                default: ;
            }
        }
        uint8_t  r = reg->regAddr;
        uint32_t v = reg->val;
        // Implement commands based on Device / register
        switch( dev ){
            case FMC150_DEV_ADS62P49:
                FMC150_PRNT_HLP("ADS62P49(  ");
                ads62p49_write_reg(r,v);
                retVal = (ads62p49_read_reg(r)==v) ? RET_OK : RET_ERR_SPI;
                break;
            case FMC150_DEV_AMC7823:
                FMC150_PRNT_HLP("AMC7823(   ");
                // Always write to page 1
                amc7823_write_reg(1,r,v);
                retVal = (amc7823_read_reg(1,r)==v) ? RET_OK : RET_ERR_SPI;
                break;
            case FMC150_DEV_CDCE72010:
                FMC150_PRNT_HLP("CDCE72010( ");
                cdce72010_write_reg(r,v);
                // Skip check as reset bits read back differently
                if(r==0x0C) {
                    retVal = RET_OK;
                } else {
                    retVal = (cdce72010_read_reg(r)==v) ? RET_OK : RET_ERR_SPI;
                }
                break;
            case FMC150_DEV_DAC3283:
                FMC150_PRNT_HLP("DAC3283(   ");
                dac3283_write_reg(r,v);
                retVal = (dac3283_read_reg(r)==v) ? RET_OK : RET_ERR_SPI;
                break;
            case FMC150_DEV_LOCAL:
                if     (r==LOC_ADC_PRINT){ printEye(v);              }
                else if(r==LOC_ADC_ALIGN){ retVal=setIdelays();      }
                else if(r==LOC_DAC_TXEN ){ DAC3283_TXENABLE(v);      }
                else if(r==LOC_CDC_POWER){ CDCE72010_POWER_EN(v);    }
                else if(r==LOC_CDC_REF  ){ CDCE72010_REF_EN(v);      }
                else if(r==LOC_DAC_TPCHK){ retVal=dac3283_check_tp();}
                else if(r==LOC_FMC_RST  ){ retVal=reset_fmc150();    }
                else if(r==LOC_DAC_ALCHK){
                    print_str("dac3283_check_al()        ");
                    retVal=dac3283_check_al();
                }
                break;
            case FMC150_DEV_ILLEGAL: return true;
            default: ;
        }
        // Let the user break on error by returning `false` in errorHook()
        if( !errorHook(retVal) ){
            print_str("\nFMC150 init_fmc150() aborted!\n");
            return false;
        }
        if( retVal!=RET_UNKNOWN ) _putchar('\n');
        reg++;
    }
    return true;
}
