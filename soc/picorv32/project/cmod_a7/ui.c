#include "ui.h"
#include "settings.h"
#include <stdbool.h>
#include <stdint.h>
#include "gpio.h"
#include "uart.h"
#include "printf.h"
#include "common.h"

// React to user input from the serial port
void handleUserInput() {
    static float nBeers = 0;

    uint16_t tempC = UART_GETC(BASE_UART0);
    if (!UART_IS_DATA_OK(tempC)) return;

    switch(tempC){
        case 0x14:   // Ctrl+T = reset
            __asm__ volatile ("J 0");
            break;

        case 'B':
            printf("Cheers!\n");
            nBeers += 1;
            break;

        case 'b':
            printf("buurp!\n");
            nBeers += 0.5 + nBeers / 3;
            break;

        case 's':
            printf("Time for a nap!\n");
            nBeers /= 3;
            break;

        case 'c':
            printf("I've had %6.3f beers!", nBeers);
            if      (nBeers > 40)
                printf(" zzZZzzZZzZZZzzZZZ!\n");
            else if (nBeers > 20)
                printf(" I5m gsttfng diz$y!\n");
            else if (nBeers > 10)
                printf(" I'm getting dizzy!\n");
            else
                _putchar('\n');
            break;

        case '?':
            _putchar('\n');
            printf("?    Help\n");
            printf("B    Drink a beer\n");
            printf("b    Drink half a beer\n");
            printf("s    Sleep\n");
            printf("c    Count bottles\n");
            _putchar('\n');
            break;

        // any other key is echoed back
        default:
            _putchar(tempC);
            return;
    }
}
