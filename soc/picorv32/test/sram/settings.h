#ifndef SETTINGS_H
#define SETTINGS_H

#define F_CLK                   (1200000 * 625 / 8) // [Hz] for CMODA7

// Base addresses of Peripherals
#define BASE_MEM                0x00000000
#define BASE_SRAM               0x01000000
#define BASE_UART0              0x02000000
#define BASE_GPIO               0x03000000

#define SRAM_SIZE               (1 << 19)  // [bytes]

//IRQ when byte received. Cleared when byte read from UART_RX_REG
#define IRQ_UART0_RX            0x03

// bootloader / debug UART
#define BOOTLOADER_DELAY        (F_CLK / 1000)

#endif
