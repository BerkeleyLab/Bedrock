#include <stdint.h>
#include "settings.h"
#include "print.h"
#include "uart.h"
#include "i2c_soft.h"
#include "lcd.h"
#include "gpio.h"
#include "timer.h"

#define P_UART (1<<0)
#define P_LCD  (1<<1)

// print to: 1=UART, 2=LCD, 3=BOTH
unsigned g_printTo = P_UART;

void _putchar(char c)
{
    if(g_printTo & P_UART) UART_PUTC(BASE_UART0, c);
    if(g_printTo & P_LCD) lcd_putc(c);
}

// Set the channel mask register of the PCA9584 I2C multiplexer
// if you want to speak to channel 7:  ch = (1<<7)
// Returns 1 on success, 0 on failure
uint8_t i2c_mux_set(uint8_t ch)
{
    // Reset PCA9584 (just in case)
    SET_GPIO1(BASE_GPIO, GPIO_OUT_REG, PIN_PCA9584_RST, 0);
    SET_GPIO1(BASE_GPIO, GPIO_OUT_REG, PIN_PCA9584_RST, 1);
    return i2c_write_regs(I2C_ADR_PCA9584, ch, 0, 0);
}

void init(void)
{
    UART_INIT(BASE_UART0, BOOTLOADER_BAUDRATE);       // Debug print (USB serial)
    // GPIO pin config
    SET_GPIO1(BASE_GPIO, GPIO_OE_REG, PIN_PCA9584_RST, 1);// Drive PCA9584 RESET pin
    SET_GPIO8(BASE_GPIO, GPIO_OE_REG, 3, 0xFF);       // Drive LEDs
    lcd_init();
    i2c_init(PIN_I2C_SDA, PIN_I2C_SCL);
}

int main(void)
{
    uint8_t ret;
    uint16_t tempBuff[5];

    init();

    print_str("\n---------------------------------------\n");
    print_str(" I2C test ");
    print_str("\n---------------------------------------\n");

    g_printTo = P_LCD;
    print_str("Hello World\n\x7E LCD works \x7F");
    g_printTo = P_UART;

    print_str("Scanning all 8 I2C busses downstream of the multiplexer...\n");
    for(int i=0; i<=7; i++) {
        i2c_mux_set(1<<i);
        print_str("    CH: ");
        print_dec(i);
        _putchar(' ');
        i2c_scan();
    }

    print_str("\n\nReading SI570 regs: ");
    i2c_mux_set(I2C_CH_SI570);
    i2c_dump(I2C_ADR_SI570, 7, 12);

    print_str("\n\nDumping SFP ID ROM at 0x");
    print_hex(I2C_ADR_SFP_1, 2);
    i2c_mux_set(I2C_CH_SFP);
    i2c_dump(I2C_ADR_SFP_1, 0, 256);

    print_str("\n\nDumping SFP diagnostics ROM at 0x");
    print_hex(I2C_ADR_SFP_2, 2);
    i2c_dump(I2C_ADR_SFP_2, 0, 256);

    print_str("\n\nVendor:    ");
    i2c_read_ascii(I2C_ADR_SFP_1, 20, 16);
    print_str("\nPN:        ");
    i2c_read_ascii(I2C_ADR_SFP_1, 40, 16);
    print_str("\nREV:       ");
    i2c_read_ascii(I2C_ADR_SFP_1, 56,  4);
    print_str("\nSN:        ");
    i2c_read_ascii(I2C_ADR_SFP_1, 68, 16);
    print_str("\nDate code: ");
    i2c_read_ascii(I2C_ADR_SFP_1, 84,  8);

    DELAY_MS(3000);

    print_str("\n\nReading SFP real-time diag.\n");
    print_str("-----------------------------------------\n");
    print_str("Temp        VCC     I_bias  P_tx     P_rx\n");
    print_str("-----------------------------------------\n");
    uint8_t i=0;
    g_printTo = P_UART | P_LCD;
    while(1) {
        ret = i2c_read_regs(I2C_ADR_SFP_2, 96, (uint8_t*)tempBuff, 10);
        if(!ret) {
            print_str("I2C error");
            return -1;
        }
        lcd_cur(0x00);
        print_dec_fix(SWAP16(tempBuff[0]), 8, 1);
        print_str(" degC ");
        print_dec(SWAP16(tempBuff[1]) / 10);
        print_str(" mV ");
        print_dec(SWAP16(tempBuff[2]) / 500);
        print_str(" mA ");
        lcd_cur(0x40);
        print_dec(SWAP16(tempBuff[3]) / 10);
        print_str(" uW ");
        print_dec(SWAP16(tempBuff[4]) / 10);
        print_str(" uW\n");
        SET_GPIO8(BASE_GPIO, GPIO_OUT_REG, 3, i++);
        DELAY_MS(200);
    }

    return 0;
}
