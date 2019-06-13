//-------------------------------------------------------------
// Functions to print to 2 line Text LCD
//-------------------------------------------------------------
// Needs the following macros in settings.h:
// #define BASE_GPIO   0x01000000
// #define LCD_DB4_LS  8
// #define LCD_DB5_LS  9
// #define LCD_DB6_LS  10
// #define LCD_DB7_LS  11
// #define LCD_RW_LS   12   // GPIO PIN of read/write line
// #define LCD_RS_LS   13   // GPIO PIN of command/data line
// #define LCD_E_LS    14   // GPIO PIN of strobe line
//
// Note that all 4 data lines must have sequential PIN numbers.
// All control and data lines must be assigned to a single
// GPIO byte (they must not cross into another byte!)

#ifndef LCD_H
#define LCD_H
#include <stdint.h>

// initialize and clear lcd
void lcd_init(void);

// low level function to send command / data to lcd
void lcd_tx( uint8_t rs, uint8_t rw, uint8_t dat );

// clear all characters and return cursor to top left
void lcd_clear(void);

// set cursor position, 1st line is from 0x00 to 0x27, 2nd line 0x40 to 0x67
void lcd_cur( uint8_t cursorPos );

// Print a single character.
 // \f clears screen, \n toggles between lines, \r goes to first line
void lcd_putc( uint8_t c );

#endif
