#include <stdint.h>
#include "sfr.h"
#include "gpio.h"
#include "printf.h"
#include "settings.h"
// #include "badger.h"

#define BASE_BADGER_CFG BASE_BADGER
#define BASE_BADGER_BUF (BASE_BADGER | 0x00010000)

#define BIT_BADGER_BUSY 16

#define BADGER_SET_START_ADDR(addr) SET_REG16(BASE_BADGER_CFG, addr)
#define BADGER_SEND() SET_SFR1(BASE_BADGER_CFG, 0, BIT_BADGER_BUSY, 1)
#define BADGER_IS_BUSY() GET_SFR1(BASE_BADGER_CFG, 0, BIT_BADGER_BUSY)

// To make printf() show up in the terminal
void _putchar(char c){
	SET_REG8(BASE_SFR, c);
}

int main(void){
    BADGER_SET_START_ADDR(0);
    SET_REG(BASE_BADGER_BUF, 8 * 4);
    for (unsigned i=0; i<8; i++)
        SET_REG((BASE_BADGER_BUF + 4 + i * 4), (0x12345670 + 8 - i));
    BADGER_SEND();
	while(BADGER_IS_BUSY());
	// printf("\nPico says: %d is 0x%02X, busy = %d\n", 42, 42, BADGER_IS_BUSY());
    // while(1);
    return 0;
}
