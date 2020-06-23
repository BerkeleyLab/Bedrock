#include <stdint.h>
#include "settings.h"
#include "irqs.h"
#include "timer.h"
#include "gpio.h"
#include "print.h"
#include "uart.h"

// hook for all print_* functions
void _putchar(char c)
{
    UART_PUTC(BASE_UART0, c);
}

// called for all 32 interrupts
// irqs = q1 = bitmask of all IRQs to be handled
uint32_t *irq(uint32_t *regs, uint32_t irqs)
{
    // char on debug UART received, ctrl + T = soft-reset
    if (irqs & (1 << IRQ_UART0_RX))
        if (UART_GETC(BASE_UART0) == 0x14)
            _picorv32_irq_reset();

    return regs;
}


uint32_t xorshift32(uint32_t *state)
{
    /* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
    uint32_t x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x;

    return x;
}

int cmd_memtest(volatile uint32_t *base, unsigned len, unsigned stride, unsigned cycles)
{
    // copied from:
    // https://github.com/cliffordwolf/picorv32/blob/master/picosoc/firmware.c
    uint32_t state;
    volatile uint8_t *base_byte = (volatile uint8_t *)base;

    print_str("Running memtest ");

    for (unsigned i = 1; i <= cycles; i++) {
        // Walk in stride increments, word access
        state = i;
        for (unsigned word = 0; word < len / 4; word += stride) {
            base[word] = xorshift32(&state);
        }

        state = i;
        for (unsigned word = 0; word < len / 4; word += stride) {
            if (base[word] != xorshift32(&state)) {
                print_str(" ***FAILED WORD*** at ");
                print_hex(4 * word, 6);
                _putchar('\n');
                return -1;
            }
        }

        // Byte access
        for (unsigned byte=0; byte<len; byte+=stride) {
            base_byte[byte] = (uint8_t)byte;
        }

        for (unsigned byte=0; byte<len; byte+=stride) {
            if (base_byte[byte] != (uint8_t)byte) {
                print_str(" ***FAILED BYTE*** at ");
                print_hex(byte, 6);
                _putchar('\n');
                return -1;
            }
        }

        _putchar('.');
    }

    print_str(" passed\n");
    return 0;
}


int main(void)
{
    UART_INIT(BASE_UART0, BOOTLOADER_BAUDRATE);
    _picorv32_irq_enable((1 << IRQ_UART0_RX));

    print_str("\n---------------------------------------\n");
    print_str(" sram test ");
    print_str("\n---------------------------------------\n");
    print_str("CTRL+T for reset ...\n");
    // DELAY_MS(5000);

    volatile uint32_t *p = (volatile uint32_t *)BASE_SRAM;

    for (unsigned i=0; i<32; i++) {
        p[i] = ((i + 3) << 24) |((i + 2) << 16) | ((i + 1) << 8) | i;
    }

    hexDump32(p, 32);
    while(cmd_memtest(p, SRAM_SIZE, 1, 256) == 0);

    while(1);

    return -1;
}
