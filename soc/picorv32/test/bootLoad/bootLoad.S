// Simulates the main user app
#include "settings.h"
.section .text
.global start

start:
    // send "!!!"
	li    gp, BASE_UART0
	li    t0, '!'
    sw    t0, 0x00(gp)
    sw    t0, 0x00(gp)
    sw    t0, 0x00(gp)
	ebreak
