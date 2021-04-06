#include <stdint.h>
#include <string.h>
#include "common.h"
#include "settings.h"
#include "uart.h"

const char buf_tx[] = "PI IS EXACTLY THREE!!!\n";
#define N_CHARS 23
char buf_rx[N_CHARS];

void uart_recv(char *p, unsigned len) {
    uint16_t c;
    for (unsigned i=0; i<len; i++){
        do {
            c = UART_GETC(BASE_UART);
        } while (!UART_IS_DATA_OK(c));
        *p++ = c & 0xFF;
    }
}

void uart_send(const char *p) {
    while (*p)
        UART_PUTC(BASE_UART, *p++);  // non blocking, fills up FIFO
}

int main(void) {
    int pass=0;
    UART_INIT(BASE_UART, 9216000);
    uart_send(buf_tx);
    for (volatile unsigned i=0; i<0xFF; i++);
    uart_recv(buf_rx, N_CHARS);
    pass = memcmp(buf_tx, buf_rx, N_CHARS) == 0;
    return pass;
}
