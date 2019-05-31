#include <stdint.h>
#include "settings.h"
#include "irqs.h"
#include "printf.h"
#include "uart.h"
#include "ui.h"
#include "gpio.h"
#include "timer.h"

void _putchar(char c){
    // hook for all print_* functions
    UART_PUTC(BASE_UART0, c);
}

uint32_t *irq(uint32_t *regs, uint32_t irqs) {
    // called for all 32 interrupts
    // *regs = context save X-registers
    // irqs = q1 = bitmask of all IRQs to be handled
    (void) irqs;
    return regs;
}

int main(void) {
    // _picorv32_irq_enable(1<<IRQ_UART1_RX);
    SET_GPIO8(BASE_GPIO, GPIO_OE_REG, 0, 0xFF);  // Drive LEDs
    UART_INIT(BASE_UART0, BOOTLOADER_BAUDRATE);  // Debug print (USB serial)

    printf("\n---------------------------------------\n");
    printf(" LBL pico_soc %s", GIT_VERSION);
    printf("\n---------------------------------------\n");
    printf("running UART0 at %d baud/s\n\n", BOOTLOADER_BAUDRATE);
    handleUserInput();
    int i=0;
    while(1){
        // Blink LEDs
        SET_GPIO8(BASE_GPIO, GPIO_OUT_REG, 0, ((i++)>>6));
        handleUserInput();
        #ifndef SIMULATION
            DELAY_MS(100);
        #endif
    }
    printf("!!! DONE, trapping the CPU on purpose !!!\n");
    return 0;
}
