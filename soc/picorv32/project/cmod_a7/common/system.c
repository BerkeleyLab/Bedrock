#include <stdint.h>
#include "settings.h"
#include "irqs.h"
#include "print.h"
#include "uart.h"
#include "gpio.h"
#include "timer.h"
#include "test.h"
#include "spi_memio.h"

void donut(void);

#define LED(val) SET_GPIO8(BASE_GPIO, GPIO_OUT_REG, 0, ((~val) & 0x7))

#ifdef SIMULATION
    // Need to speed up things when running in iverilog
    #define N_PRIMES 16
    #define HASH 0x36dbe6ba  // magic number from prime_hash.py
    #define EXIT() return(-1)
#else
    #define N_PRIMES 1024
    #define HASH 0x6bc508b6
    #define EXIT() while(1)
#endif

void _putchar(char c)
{
    // hook for all print_* functions
    UART_PUTC(BASE_UART0, c);
}

volatile unsigned chars_received = 0, last_char=0x100;
uint32_t *irq(uint32_t *regs, uint32_t irqs)
{
    // called for all 32 interrupts
    // *regs = context save X-registers
    // irqs = q1 = bitmask of all IRQs to be handled
    if (irqs & (1 << IRQ_UART0_RX)) {
        // Ctrl + T = reset
        last_char = UART_GETC(BASE_UART0);
        if (last_char == 0x14) {
            // reboot from interrupt
            _picorv32_irq_reset();
        }
        chars_received++;
    }
    return regs;
}

int main(void)
{
    UART_INIT(BASE_UART0, BOOTLOADER_BAUDRATE);  // Debug print (USB serial)
    _picorv32_irq_enable(1 << IRQ_UART0_RX);
    SET_GPIO8(BASE_GPIO, GPIO_OUT_REG, 0, 0);
    SET_GPIO8(BASE_GPIO, GPIO_OE_REG, 0, 0xFF);  // Drive LEDs

    print_str("\n---------------------------------------\n");
    print_str(" LBL pico_soc @");
    print_udec_fix(((F_CLK / 1000) << 8) / 1000, 8, 3);
    print_str(" MHz, " GIT_VERSION);
    print_str("\n---------------------------------------\n");
    print_str("running UART0 at ");
    print_dec(BOOTLOADER_BAUDRATE);
    print_str(" baud\n\n");
    print_str("`CTRL+T` to reset, `s` to sift for prime numbers, `d` for a 3D donut ...\n");
    LED(0b011);  // Ready for test, LED = yellow
    while (1) {
        if (last_char == 's')
            break;

        else if (last_char == 'd')
            donut();
    }

    // test of SPI flash memory mapping
    // only works reliably in 1x mode and only up to 68 MHz
    // DDR doesn't work (expected), neither does continuous mode (not expected)
    // 4x mode works only for in-order reads, fails for out of order reads

    // uint32_t *p_memio = (uint32_t *)BASE_MEMIO;
    // MEMIO_CFG(BASE_MEMIO, 0, 1, 1, 8);

    // unsigned volatile hash, tmp1, tmp2;
    // while (1) {
    //     hash = 5381;
    //     for (unsigned i=0; i<1048574; i+=2) {
    //         tmp2 = p_memio[i + 1];
    //         tmp1 = p_memio[i];
    //         hash = mkhash(hash, tmp1);
    //         hash = mkhash(hash, tmp2);
    //     }
    //     print_str("\nchecksum: ");
    //     print_hex(hash, 8);
    //     // value generated by bin_hash.py from flash content read by openocd
    //     if (hash != 0x90C7112A)
    //         print_str(" !!! ERROR !!!");
    // }

    LED(0b111);  // Test running, LED = white
    unsigned calc_hash = sieve(N_PRIMES);
    if (calc_hash != HASH) {
        LED(0b001);  // Test failed, LED = red
        print_str("\n\nFAIL\n");
        EXIT();
    }
    print_str(" ok\n");

    volatile unsigned *p = (volatile unsigned*)BASE_SRAM;

    // read / write the SRAM
    print_str("Running SRAM memtest ");
#ifdef SIMULATION
    int ret = cmd_memtest(p, 32, 1, 1);
#else
    int ret = cmd_memtest(p, SRAM_SIZE, 1, 32);
#endif
    if (ret != 0) {
        LED(0b001);
        for (unsigned i=0; i<32; i++)
            p[i] = ((i + 3) << 24) |((i + 2) << 16) | ((i + 1) << 8) | i;
        print_str("First 32 test-pattern words:\n");
        hexDump32((uint32_t *)p, 32);
        print_str("\n\nFAIL\n");
        EXIT();
    }

    print_str("PASS\n");
    LED(0b010);
#ifndef SIMULATION
        // Blink LEDs on test success
        int i=0;
        while(1){
            DELAY_MS(300);
            LED(i);
            i++;
        }
#endif
    // Let testbench know we are happy
    return 0x1234;
}
