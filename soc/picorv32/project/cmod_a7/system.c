#include <stdint.h>
#include "settings.h"
#include "irqs.h"
#include "print.h"
#include "uart.h"
#include "gpio.h"
#include "timer.h"
#include "test.h"

void _putchar(char c){
    // hook for all print_* functions
    UART_PUTC(BASE_UART0, c);
}

volatile unsigned chars_received = 0;
uint32_t *irq(uint32_t *regs, uint32_t irqs) {
    // called for all 32 interrupts
    // *regs = context save X-registers
    // irqs = q1 = bitmask of all IRQs to be handled
    if (irqs & (1 << IRQ_UART0_RX)) {
        // Ctrl + T = reset
        if (UART_GETC(BASE_UART0) == 0x14) {
            // reboot from interrupt
            _picorv32_irq_reset();
        }
        chars_received++;
    }
    return regs;
}

int main(void) {
    unsigned hash;

    UART_INIT(BASE_UART0, BOOTLOADER_BAUDRATE);  // Debug print (USB serial)
    _picorv32_irq_enable(1 << IRQ_UART0_RX);
    SET_GPIO8(BASE_GPIO, GPIO_OUT_REG, 0, 0);
    SET_GPIO8(BASE_GPIO, GPIO_OE_REG, 0, 0xFF);  // Drive LEDs

    print_str("\n---------------------------------------\n");
    print_str(" LBL pico_soc "); print_str(GIT_VERSION);
    print_str("\n---------------------------------------\n");
    print_str("running UART0 at ");
    print_dec(BOOTLOADER_BAUDRATE);
    print_str(" baud/s\n\n");
    print_str("CTRL+T for reset, `any key` to start sieving for prime numbers ...\n");
    while(chars_received == 0);

    // Test running, LED = white
    SET_GPIO8(BASE_GPIO, GPIO_OUT_REG, 0, 0b0111);
    hash = sieve(1024);
    // magic number from get_hash.py
    if (hash != 0x6bc508b6) {
        // Test failed, LED = red
        SET_GPIO8(BASE_GPIO, GPIO_OUT_REG, 0, 0b0001);
        print_str("FAIL\n");
        return -1;  // trap
    }

    print_str("PASS\n");
    #ifndef SIMULATION
        // Blink LEDs on test success
        int i=0;
        while(1){
            SET_GPIO8(BASE_GPIO, GPIO_OUT_REG, 0, ((i++)>>6));
            DELAY_MS(100);
        }
    #endif
    return 0;
}
