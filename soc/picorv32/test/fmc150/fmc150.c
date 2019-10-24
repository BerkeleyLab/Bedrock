#include <stdint.h>
#include "common.h"
#include "settings.h"
#include "ads62p49.h"

int main(void){
    for (unsigned i=0; i<=13; i++){
        ADS62P49_SET_IDELAY( i, i+1 );
    }

    for (unsigned i=0; i<31; i++) ADS62P49_SET_IDELAY( 14, i );

    return ADS62P49_GET_SAMPLES(0,1);
}
