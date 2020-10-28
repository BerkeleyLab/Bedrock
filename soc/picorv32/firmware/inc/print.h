//-------------------------------------------------------------
// Minimalistic print functions
//-------------------------------------------------------------
// Note that the _putchar function needs to be implemented by the user!
// For example to print to UART, add this line to your code:
// void _putchar(char c){ UART_PUTC(BASE_DEBUG_UART, c); }

#ifndef PRINT_H
#define PRINT_H
#include <stdint.h>

// Print a single character (see note above!)
void _putchar(char c);

// Print an integer as N hex digits
void print_hex(uint32_t val, uint8_t digits);

// Print a signed integer as decimal number
void print_dec(int32_t val);

// Print an unsigned integer as decimal number
void print_udec(uint32_t val);

// Print a fixed point fractional number
// with `nFract` fractional bits and print only `nDigits` after the .
void print_udec_fix(uint32_t val, const uint8_t nFract, uint8_t nDigits);
void print_dec_fix(  int32_t val, const uint8_t nFract, uint8_t nDigits);

// Print a zero terminated string
void print_str(const char *p);

// Print a memory region as 8-bit ordered hexdump
void hexDump(uint8_t *buffer, uint16_t nBytes);

// Print a memory region as 32-bit ordered hexdump
void hexDump32(uint32_t *buffer, uint16_t nWords);

#endif
