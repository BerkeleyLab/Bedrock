#include <stdint.h>
#include "settings.h"
#include "print.h"
#include "gpio.h"
#include "common.h"
#include "timer.h"
#include "lcd.h"

static void lcdStrobe(void) {
    SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, LCD_E_LS, 1 );
    DELAY_US(1);
    SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, LCD_E_LS, 0 );
}

void lcd_tx( uint8_t rs, uint8_t rw, uint8_t dat ){
    SET_GPIO8(
        BASE_GPIO,
        GPIO_OUT_REG,
        LCD_DB4_LS/8,
        (rw<<(LCD_RW_LS%8)) | (rs<<(LCD_RS_LS%8)) | ((dat>>4)<<(LCD_DB4_LS%8))
    );
    lcdStrobe();
    SET_GPIO8(
        BASE_GPIO,
        GPIO_OUT_REG,
        LCD_DB4_LS/8,
        (rw<<(LCD_RW_LS%8)) | (rs<<(LCD_RS_LS%8)) | ((dat&0x0F)<<(LCD_DB4_LS%8))
    );
    lcdStrobe();
    DELAY_US( 37 );
}

void lcd_clear(void){
    lcd_tx( 0, 0, 0b00000001 );  // Clear Display
    DELAY_US( 1600 );
}

void lcd_cur( uint8_t cursorPos ){
    lcd_tx( 0, 0, cursorPos | 0x80 );
}

void lcd_init(void){
    // All LCD lines are outputs now
    SET_GPIO8( BASE_GPIO, GPIO_OE_REG,  LCD_DB4_LS/8, 0xFF );
    SET_GPIO8( BASE_GPIO, GPIO_OUT_REG, LCD_DB4_LS/8, (1<<(LCD_DB5_LS%8)) );
    lcdStrobe();
    DELAY_US( 37 );
    // Now we should be in 4 bit mode
    lcd_tx( 0, 0, 0b00101000 );  // 2 lines mode, 5x8 font
    lcd_tx( 0, 0, 0b00001100 );  // Display on, cursor off, cursor position off
    lcd_clear();
}

void lcd_putc( const uint8_t c ){
    static unsigned currentLine = 0;
    switch (c) {
        case '\f':  // Form feed = clear LCD
            lcd_clear();
            currentLine = 0;
            break;
        case '\n':  // New line = toggle between 1st and second line
        case '\v':  // Cause newline only on LCD
            if( currentLine==0 ){
                currentLine = 1;
                lcd_cur( 0x40 );
            } else {
                lcd_cur( 0x00 );
                currentLine = 0;
            }
            break;
        case '\r':  // Carriage return = go to first line
            lcd_cur( 0x00 );
            currentLine = 0;
            break;
        default:
            lcd_tx( 1, 0, c );
    }
}
